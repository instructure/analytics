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

require_relative '../../../../../spec/spec_helper'
require_relative '../cassandra_spec_helper'

describe PageView do
  before :each do
    Setting.set('enable_page_views', 'db')
  end

  describe "#category" do
    before :each do
      @view = page_view_model
    end

    it "should be :other if controller is nil" do
      expect(@view.category).to eq :other
    end

    it "should recognize known controllers" do
      @view.controller = 'assignments'
      expect(@view.category).to eq :assignments
    end

    it "should be :other for unknown controllers" do
      @view.controller = 'unknown'
      expect(@view.category).to eq :other
    end

    it "should prefer the category attribute if any" do
      expect(@view).to receive(:read_attribute).with(:category).and_return('category')
      expect(@view.category).to eq 'category'
    end
  end

  def page_view(opts = {})
    view = page_view_model(opts)

    if opts[:participated]
      view.participated = true
      access = AssetUserAccess.new
      access.context = view.context
      access.display_name = 'Some Asset'
      access.action_level = 'participate'
      access.participate_score = 1
      access.user = view.user
      access.save!
      view.asset_user_access = access
      view.save!
    end

    view.store
    view
  end

  it "should always flag new page views as summarized" do
    view = page_view
    expect(view).to be_summarized
  end

  it "should not automatically summarize existing non-summarized page views on save" do
    # set up unsummarized page view
    view = page_view
    view.summarized = false
    view.save
    view.reload

    # re-save, shouldn't become summarized
    view.save
    expect(view).not_to be_summarized
  end

  it "should increment the rollup when a new page view is created" do
    date = Date.today
    course = course_model
    expect(PageViewsRollup.bin_for(course, date, 'other').views).to eq 0

    view = page_view(:context => course, :created_at => date)
    expect(PageViewsRollup.bin_for(course, date, 'other').views).to eq 1
  end

  it "should assign new page view to bin by utc date" do
    # 2012-06-01 20:00:00 AKDT / 2012-06-02 04:00:00 UTC
    time = Time.zone.parse('2012-06-01 20:00:00-08:00').in_time_zone('Alaska')
    course = course_model
    view = page_view(:context => course, :created_at => time)
    expect(PageViewsRollup.bin_for(course, time.to_date, 'other').views).to eq 0
    expect(PageViewsRollup.bin_for(course, time.utc.to_date, 'other').views).to eq 1
  end

  shared_examples_for ".participations_for_context" do
    before do
      student_in_course(:active_all => true)
    end

    it "should return a object for each participation" do
      page_view(:user => @user, :context => @course, :participated => true)
      page_view(:user => @user, :context => @course, :participated => true)
      page_view(:user => @user, :context => @course)
      parts = PageView.participations_for_context(@course, @user)
      expect(parts.size).to eq 2
      parts.each { |p| expect(p.key?(:created_at)).to be_truthy }
    end

    it "should update when participating on a group context" do
      group_model(:context => @course)
      @group.add_user(@user, 'accepted')
      page_view(:user => @user, :context => @group, :participated => true)
      parts = PageView.participations_for_context(@course, @user)
      expect(parts.count).to eq 1
    end
  end

  describe ".participations_for_context db" do
    include_examples ".participations_for_context"
  end

  describe ".participations_for_context cassandra" do
    include_examples "analytics cassandra page views"
    include_examples ".participations_for_context"
  end

  describe ".counters_by_context_and_hour db" do
    before do
      student_in_course(:active_all => true)
    end

    it "should return user page view counts in the course by hour" do
      timewarp = Time.parse('2012-12-26T19:15:00Z')
      allow(Time).to receive(:now).and_return(timewarp)
      page_view(:user => @user, :context => @course, :created_at => 2.days.ago)
      page_view(:user => @user, :context => @course, :created_at => 2.days.ago)
      page_view(:user => @user, :context => @course, :created_at => 3.hours.ago)
      page_view(:user => @user, :context => @course, :created_at => 1.hour.ago)
      page_view(:user => @user, :context => @course, :created_at => 1.hour.ago)
      counts = PageView.counters_by_context_and_hour(@course, @user)
      expect(counts.size).to eq 2
      expect(counts.values.sum).to eq 5
    end

    it "should return user page view counts in course groups" do
      timewarp = Time.parse('2012-12-26T19:15:00Z')
      allow(Time).to receive(:now).and_return(timewarp)

      group_model(:context => @course)
      @group.add_user(@user, 'accepted')

      page_view(:user => @user, :context => @group, :created_at => 2.days.ago)
      page_view(:user => @user, :context => @group, :created_at => 2.days.ago)
      page_view(:user => @user, :context => @group, :created_at => 3.hours.ago)
      page_view(:user => @user, :context => @group, :created_at => 1.hour.ago)
      page_view(:user => @user, :context => @group, :created_at => 1.hour.ago)
      counts = PageView.counters_by_context_and_hour(@course, @user)
      expect(counts.size).to eq 2
      expect(counts.values.sum).to eq 5
    end
  end

  # these tests are not shared with the db tests above, because cassandra
  # actually changes the behavior here -- it puts the counts in one-hour
  # buckets instead of 24-hour buckets, to solve the problem of people viewing
  # analytics from different timezones.
  describe ".counters_by_context_and_hour cassandra" do
    include_examples "analytics cassandra page views"

    before do
      student_in_course(:active_all => true)
    end

    it "should return user page view counts in the course by hour" do
      timewarp = Time.parse('2012-12-26T19:15:00Z')
      allow(Time).to receive(:now).and_return(timewarp)
      page_view(:user => @user, :context => @course, :created_at => 2.days.ago)
      page_view(:user => @user, :context => @course, :created_at => 2.days.ago)
      page_view(:user => @user, :context => @course, :created_at => 3.hours.ago)
      page_view(:user => @user, :context => @course, :created_at => 1.hour.ago)
      page_view(:user => @user, :context => @course, :created_at => 1.hour.ago)
      counts = PageView.counters_by_context_and_hour(@course, @user)
      expect(counts.size).to eq 3
      expect(counts.values.sum).to eq 5
    end

    it "should return user page view counts in course groups" do
      timewarp = Time.parse('2012-12-26T19:15:00Z')
      allow(Time).to receive(:now).and_return(timewarp)

      group_model(:context => @course)
      @group.add_user(@user, 'accepted')

      page_view(:user => @user, :context => @group, :created_at => 2.days.ago)
      page_view(:user => @user, :context => @group, :created_at => 2.days.ago)
      page_view(:user => @user, :context => @group, :created_at => 3.hours.ago)
      page_view(:user => @user, :context => @group, :created_at => 1.hour.ago)
      page_view(:user => @user, :context => @group, :created_at => 1.hour.ago)
      counts = PageView.counters_by_context_and_hour(@course, @user)
      expect(counts.size).to eq 3
      expect(counts.values.sum).to eq 5
    end
  end

  shared_examples_for ".counters_by_context_for_users" do
    before do
      @user1 = student_in_course(:active_all => true).user
      @user2 = student_in_course(:active_all => true).user
    end

    it "should return user total page views and participants counts" do
      page_view(:user => @user1, :context => @course, :participated => true,  :created_at => 2.days.ago)
      page_view(:user => @user1, :context => @course, :participated => false, :created_at => 11.months.ago)
      page_view(:user => @user1, :context => @course, :participated => true,  :created_at => 1.hour.ago)
      page_view(:user => @user1, :context => @course, :participated => true,  :created_at => 1.hour.ago)

      page_view(:user => @user2, :context => @course, :participated => true,  :created_at => 1.day.ago)
      page_view(:user => @user2, :context => @course, :participated => false, :created_at => 1.hour.ago)
      page_view(:user => @user2, :context => @course, :participated => false, :created_at => 1.hour.ago)
      page_view(:user => @user2, :context => @course, :participated => false, :created_at => 1.hour.ago)
      page_view(:user => @user2, :context => @course, :participated => false, :created_at => 1.hour.ago)

      counts = PageView.counters_by_context_for_users(@course, [@user1.id, @user2.id])
      expect(counts).to eq({ @user1.id => { :page_views => 4, :participations => 3 },
                         @user2.id => { :page_views => 5, :participations => 1 },
      })

      # partial retrieval
      expect(PageView.counters_by_context_for_users(@course, [@user2.id])).to eq({ @user2.id => counts[@user2.id] })
    end

    it "should return user total page views and participants counts with groups" do
      group_model(:context => @course)
      @group.add_user(@user, 'accepted')

      page_view(:user => @user1, :context => @group, :participated => true,  :created_at => 2.days.ago)
      page_view(:user => @user1, :context => @group, :participated => false, :created_at => 11.months.ago)
      page_view(:user => @user1, :context => @group, :participated => true,  :created_at => 1.hour.ago)

      page_view(:user => @user2, :context => @group, :participated => true,  :created_at => 1.day.ago)
      page_view(:user => @user2, :context => @group, :participated => false, :created_at => 1.hour.ago)


      counts = PageView.counters_by_context_for_users(@course, [@user1.id, @user2.id])
      expect(counts).to eq({ @user1.id => { :page_views => 3, :participations => 2 },
        @user2.id => { :page_views => 2, :participations => 1 },
      })

      # partial retrieval
      expect(PageView.counters_by_context_for_users(@course, [@user2.id])).to eq({ @user2.id => counts[@user2.id] })
    end
  end

  describe ".counters_by_context_for_users db" do
    include_examples ".counters_by_context_for_users"
  end

  describe ".counters_by_context_for_users cassandra" do
    include_examples ".counters_by_context_for_users"
    include_examples "analytics cassandra page views"
  end
end
