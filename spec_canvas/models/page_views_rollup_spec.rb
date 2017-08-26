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

require_relative '../../../../../spec/sharding_spec_helper'

describe PageViewsRollup do
  def create_rollup(opts={})
    rollup = PageViewsRollup.new
    rollup.course = opts[:course]
    rollup.date = opts[:date]
    rollup.category = opts[:category]
    rollup.save unless opts[:no_save]
    rollup
  end

  describe ".for_dates" do
    before :each do
      @course = course_model
    end

    it "should work for a single date" do
      today = Date.today
      rollup = create_rollup(:course => @course, :date => today, :category => 'other')
      other = create_rollup(:course => @course, :date => today - 1.day, :category => 'other')
      expect(PageViewsRollup.for_dates(today)).to include(rollup)
      expect(PageViewsRollup.for_dates(today)).not_to include(other)
    end

    it "should work for a date range" do
      end_day = Date.today - 1.day
      start_day = end_day - 3.days

      rollups = (start_day..end_day).map do |day|
        create_rollup(:course => @course, :date => day, :category => 'other')
      end
      before_start = create_rollup(:course => @course, :date => start_day - 1.day, :category => 'other')
      after_end = create_rollup(:course => @course, :date => end_day + 1.day, :category => 'other')

      rollups.each do |rollup|
        expect(PageViewsRollup.for_dates(start_day..end_day)).to include(rollup)
      end
      expect(PageViewsRollup.for_dates(start_day..end_day)).not_to include(before_start)
      expect(PageViewsRollup.for_dates(start_day..end_day)).not_to include(after_end)
    end
  end

  describe ".for_category" do
    before :each do
      @course = course_model
      @today = Date.today
    end

    it "should include all rollups for that category" do
      rollup1 = create_rollup(:course => @course, :date => @today, :category => 'first')
      rollup2 = create_rollup(:course => course_model, :date => @today, :category => 'first')
      expect(PageViewsRollup.for_category('first')).to include(rollup1)
      expect(PageViewsRollup.for_category('first')).to include(rollup2)
    end

    it "should only include rollups for that category" do
      rollup1 = create_rollup(:course => @course, :date => @today, :category => 'first')
      rollup2 = create_rollup(:course => @course, :date => @today, :category => 'second')
      expect(PageViewsRollup.for_category('first')).to include(rollup1)
      expect(PageViewsRollup.for_category('first')).not_to include(rollup2)
    end
  end

  describe ".bin_for" do
    before :each do
      @course = course_model
      @today = Date.today
      @category = 'other'
    end

    context "new bin" do
      before :each do
        @bin = PageViewsRollup.bin_for(@course, @today, @category)
      end

      it "should be a new record" do
        expect(@bin).to be_new_record
      end

      it "should initialize views to 0 on a new bin" do
        expect(@bin.views).to eq 0
      end

      it "should initialize participations to 0 on a new bin" do
        expect(@bin.participations).to eq 0
      end
    end

    context "existing bin" do
      before :each do
        @initial = PageViewsRollup.bin_for(@course, @today, @category)
        @initial.views = 5
        @initial.participations = 2
        @initial.save

        @existing = PageViewsRollup.bin_for(@course, @today, @category)
      end

      it "should not return new bin" do
        expect(@existing).to eq @initial
      end

      it "should not reset views" do
        expect(@existing.views).to eq @initial.views
      end

      it "should not reset participations" do
        expect(@existing.participations).to eq @initial.participations
      end
    end

    context "sharding" do
      specs_require_sharding

      context "new bin" do
        it "should return a bin on the correct shard given an AR object" do
          @shard1.activate do
            bin = PageViewsRollup.bin_for(@course, @today, @category)
            expect(bin.shard).to eq @course.shard
            expect(bin.course_id).to eq @course.id
          end
        end

        it "should return a bin on the correct shard given a non-local id" do
          @shard1.activate do
            bin = PageViewsRollup.bin_for(@course.id, @today, @category)
            expect(bin.shard).to eq @course.shard
            expect(bin.course_id).to eq @course.id
          end
        end
      end

      context "existing bin" do
        before do
          @existing = PageViewsRollup.bin_for(@course, @today, @category)
          @existing.save!
        end

        it "should return the correct bin given an AR object" do
          @shard1.activate do
            expect(PageViewsRollup.bin_for(@course, @today, @category)).to eq @existing
          end
        end

        it "should return the correct bin given a non-local id" do
          @shard1.activate do
            expect(PageViewsRollup.bin_for(@course.id, @today, @category)).to eq @existing
          end
        end
      end
    end

    context "non-Date dates" do
      before :each do
        @expected_date = Date.new(2016, 6, 21)
        # Jun 21, 2016 at 3am UTC
        as_timestamp = @expected_date.in_time_zone('UTC') + 3.hours
        # Jun 20, 2016 at 9pm MDT
        @input_timestamp = as_timestamp.in_time_zone('America/Denver')
        @scope = PageViewsRollup.bin_scope_for(@course)
      end

      it "should cast to the corresponding UTC date on query" do
        expect(@scope).to receive(:for_dates).with(@expected_date).and_return(@scope)
        PageViewsRollup.bin_for(@scope, @input_timestamp, @category)
      end

      it "should cast to same corresponding UTC date in new bin" do
        bin = PageViewsRollup.bin_for(@scope, @input_timestamp, @category)
        expect(bin.date).to eq @expected_date
      end
    end
  end

  describe "#augment" do
    before :each do
      @bin = PageViewsRollup.bin_for(course_model, Date.today, 'other')
    end

    it "should increase views" do
      expect(@bin.views).to eq 0
      @bin.augment(5, 2)
      expect(@bin.views).to eq 5
      @bin.augment(5, 2)
      expect(@bin.views).to eq 10
    end

    it "should increase participations" do
      expect(@bin.participations).to eq 0
      @bin.augment(5, 2)
      expect(@bin.participations).to eq 2
      @bin.augment(5, 2)
      expect(@bin.participations).to eq 4
    end
  end

  describe ".augment!" do
    it "should augment the appropriate bin and save" do
      @course = course_model
      @today = Date.today
      @category = 'other'

      bin = double('bin')
      scope = double('scope')
      allow(scope).to receive(:transaction).and_yield
      allow(PageViewsRollup).to receive(:bin_scope_for).with(@course).and_return(scope)
      allow(PageViewsRollup).to receive(:bin_for).with(scope, @today, @category).and_return(bin)
      expect(bin).to receive(:new_record?).and_return(false)
      expect(bin).to receive(:augment).with(5, 2).once
      expect(bin).to receive(:save!).once

      PageViewsRollup.augment!(@course, @today, @category, 5, 2)
    end

    it 'handles creation race condition' do
      course = course_model
      today = Date.today
      category = 'other'

      scope = PageViewsRollup.bin_scope_for(course)
      bin1 = PageViewsRollup.bin_for(scope, today, category)
      bin2 = PageViewsRollup.bin_for(scope, today, category)
      bin2.save!
      expect(PageViewsRollup).to receive(:bin_scope_for).and_return(scope)
      expect(PageViewsRollup).to receive(:bin_for).twice.with(scope, today, category).and_return(bin1, bin2)

      PageViewsRollup.augment!(course, today, category, 5, 2)
    end
  end

  describe ".increment_db!" do
    it "should augment the appropriate bin by 1" do
      @course = course_model
      @today = Date.today
      @category = 'other'

      expect(PageViewsRollup).to receive(:augment!).with(@course, @today, @category, 1, 1).once
      PageViewsRollup.increment_db!(@course, @today, @category, true)
    end

    it "should augment the bin's participations only if participated" do
      @course = course_model
      @today = Date.today
      @category = 'other'

      expect(PageViewsRollup).to receive(:augment!).with(@course, @today, @category, 1, 0).once
      PageViewsRollup.increment_db!(@course, @today, @category, false)
    end
  end

  if Canvas.redis_enabled?
    context "with redis" do
      before(:each) do
        Setting.set("page_view_rollups_method", "redis")
      end

      describe ".increment_cached!" do
        it "should increment via redis and a batch job" do
          @course = course_model
          @today = Date.today
          @category = 'other'

          PageViewsRollup.increment!(@course, @today, @category, false)
          expect(PageViewsRollup.count).to eq 0

          PageViewsRollup.process_cached_rollups
          expect(PageViewsRollup.count).to eq 1

          pvr = PageViewsRollup.last
          expect(pvr.course_id).to eq @course.id
          expect(pvr.date).to eq @today
          expect(pvr.category).to eq @category
          expect(pvr.views).to eq 1
          expect(pvr.participations).to eq 0

          # you should be able to supply Course or course_id
          PageViewsRollup.increment!(@course.id, @today, @category, true)
          expect(PageViewsRollup.count).to eq 1

          PageViewsRollup.process_cached_rollups
          expect(PageViewsRollup.count).to eq 1

          pvr = PageViewsRollup.last
          expect(pvr.views).to eq 2
          expect(pvr.participations).to eq 1
        end
      end
    end
  end
end
