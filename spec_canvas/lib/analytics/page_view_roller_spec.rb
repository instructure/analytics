# frozen_string_literal: true

#
# Copyright (C) 2014 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

module Analytics
  describe PageViewRoller do
    def build_page_view(opts = {})
      context = opts[:context] || @course
      user = opts[:user] || @user

      page_view = page_view_model(
        context:,
        user:,
        controller: opts[:controller]
      )

      needs_save = false

      if opts[:created_at]
        page_view.created_at = opts[:created_at]
        needs_save = true
      end

      unless opts[:summarized]
        page_view.summarized = nil
        needs_save = true
      end

      if opts[:participated]
        page_view.participated = true
        access = page_view.build_asset_user_access unless opts[:exclude_asset_user_access]
        access.display_name = "Some Asset"
        needs_save = true
      end

      page_view.save if needs_save
      page_view
    end

    before do
      @course = course_model
      @user = user_model
    end

    describe "#start_day" do
      it "returns nil with no page views" do
        expect(PageViewRoller.start_day).to be_nil
      end

      it "does not include page_views without a non-course context" do
        build_page_view(context: Account.default)
        expect(PageViewRoller.start_day).to be_nil
      end

      it "does not include summarized page_views" do
        build_page_view(summarized: true)
        expect(PageViewRoller.start_day).to be_nil
      end

      it "returns the earliest page_view's created_at" do
        date1 = Time.zone.today - 1.day
        date2 = Time.zone.today - 2.days
        [date1, date2].each { |date| build_page_view(created_at: date) }
        expect(PageViewRoller.start_day).to eq date2
      end
    end

    describe "#end_day" do
      it "returns nil with no page views" do
        expect(PageViewRoller.end_day).to be_nil
      end

      it "returns the earliest existing rollup's date" do
        date1 = Time.zone.today - 1.day
        date2 = Time.zone.today - 2.days
        build_page_view(created_at: date2)
        [date1, date2].each { |date| PageViewsRollup.bin_for(@course, date, "other").save }
        expect(PageViewRoller.end_day).to eq date2
      end

      it "returns today if no existing rollup's but existing page views" do
        build_page_view(created_at: Time.zone.today - 2.days)
        PageViewsRollup.delete_all
        expect(PageViewRoller.end_day).to eq Time.zone.today
      end

      it "ignores rollups before overridden start_day" do
        date1 = Time.zone.today - 1.day
        date2 = Time.zone.today - 2.days
        build_page_view(created_at: date2)
        [date1, date2].each { |date| PageViewsRollup.bin_for(@course, date, "other").save }
        expect(PageViewRoller.end_day(start_day: date1)).to eq date1
      end
    end

    describe "#rollup_one" do
      def mockbin(course, date, category, new_record: true)
        mockbin = double("fake bin")
        expect(PageViewsRollup).to receive(:bin_for).with(course, date, category).once.and_return(mockbin)
        allow(mockbin).to receive(:new_record?).and_return(new_record)
        allow(mockbin).to receive(:save!)
        yield mockbin if block_given?
        mockbin
      end

      it "bins page views on that day" do
        date = Time.zone.today
        build_page_view(created_at: date)
        build_page_view(created_at: date)
        mockbin(@course.id, date, "other") do |bin|
          expect(bin).to receive(:augment).with(2, 0).once
          expect(bin).to receive(:save!).once
        end
        PageViewRoller.rollup_one(date)
      end

      it "only bins page views on that day" do
        date = Time.zone.today
        build_page_view(created_at: date)
        expect(PageViewsRollup).not_to receive(:augment!)
        PageViewRoller.rollup_one(date - 1.day)
      end

      it "bins by course" do
        first_course = @course
        second_course = course_model
        date = Time.zone.today
        build_page_view(context: first_course, created_at: date)
        build_page_view(context: first_course, created_at: date)
        build_page_view(context: second_course, created_at: date)
        expect(mockbin(first_course.id, date, "other")).to receive(:augment).with(2, 0).once
        expect(mockbin(second_course.id, date, "other")).to receive(:augment).with(1, 0).once
        PageViewRoller.rollup_one(date)
      end

      it "bins by category" do
        date = Time.zone.today
        build_page_view(controller: "gradebooks", created_at: date)
        build_page_view(controller: "discussion_topics", created_at: date)
        build_page_view(controller: "discussion_topics", created_at: date)
        expect(mockbin(@course.id, date, "grades")).to receive(:augment).with(1, 0).once
        expect(mockbin(@course.id, date, "discussions")).to receive(:augment).with(2, 0).once
        PageViewRoller.rollup_one(date)
      end

      it "skips existing bins" do
        date = Time.zone.today
        build_page_view(created_at: date)
        mockbin(@course.id, date, "other", new_record: false) do |bin|
          expect(bin).not_to receive(:augment)
          expect(bin).not_to receive(:save!)
        end
        PageViewRoller.rollup_one(date)
      end

      it "recognizes participations" do
        date = Time.zone.today
        build_page_view(participated: true, created_at: date)
        expect(mockbin(@course.id, date, "other")).to receive(:augment).with(1, 1).once
        PageViewRoller.rollup_one(date)
      end
    end

    describe "#rollup_all" do
      it "rollups each day between start and end in reverse order" do
        start_day = Time.zone.today - 4.days
        end_day = Time.zone.today
        allow(PageViewRoller).to receive_messages(start_day:, end_day:)
        (start_day..end_day).reverse_each do |day|
          expect(PageViewRoller).to receive(:rollup_one).with(day, anything).ordered
        end
        PageViewRoller.rollup_all
      end
    end
  end
end
