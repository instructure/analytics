require File.expand_path(File.dirname(__FILE__) + '/../../../../../spec/spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../cassandra_spec_helper')

describe PageView do
  before :each do
    Setting.set('enable_page_views', 'db')
  end

  describe "#category" do
    before :each do
      @view = page_view_model
    end

    it "should be :other if controller is nil" do
      @view.category.should == :other
    end

    it "should recognize known controllers" do
      @view.controller = 'assignments'
      @view.category.should == :assignments
    end

    it "should be :other for unknown controllers" do
      @view.controller = 'unknown'
      @view.category.should == :other
    end

    it "should prefer the category attribute if any" do
      @view.write_attribute(:category, 'category')
      @view.category.should == 'category'
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
    view.should be_summarized
  end

  it "should not automatically summarize existing non-summarized page views on save" do
    # set up unsummarized page view
    view = page_view
    view.summarized = false
    view.save
    view.reload

    # re-save, shouldn't become summarized
    view.save
    view.should_not be_summarized
  end

  it "should increment the rollup when a new page view is created" do
    date = Date.today
    course = course_model
    PageViewsRollup.bin_for(course, date, 'other').views.should == 0

    view = page_view(:context => course, :created_at => date)
    PageViewsRollup.bin_for(course, date, 'other').views.should == 1
  end

  it "should assign new page view to bin by utc date" do
    # 2012-06-01 20:00:00 AKDT / 2012-06-02 04:00:00 UTC
    time = Time.zone.parse('2012-06-01 20:00:00-08:00').in_time_zone('Alaska')
    course = course_model
    view = page_view(:context => course, :created_at => time)
    PageViewsRollup.bin_for(course, time.to_date, 'other').views.should == 0
    PageViewsRollup.bin_for(course, time.utc.to_date, 'other').views.should == 1
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
      parts.size.should == 2
      parts.each { |p| p.key?(:created_at).should be_true }
    end
  end

  describe ".participations_for_context db" do
    it_should_behave_like ".participations_for_context"
  end

  describe ".participations_for_context cassandra" do
    it_should_behave_like "analytics cassandra page views"
    it_should_behave_like ".participations_for_context"
  end

  describe ".counters_by_context_and_hour db" do
    before do
      student_in_course(:active_all => true)
    end

    it "should return user page view counts in the course by hour" do
      timewarp = Time.parse('2012-12-26T19:15:00Z')
      Time.stubs(:now).returns(timewarp)
      page_view(:user => @user, :context => @course, :created_at => 2.days.ago)
      page_view(:user => @user, :context => @course, :created_at => 2.days.ago)
      page_view(:user => @user, :context => @course, :created_at => 3.hours.ago)
      page_view(:user => @user, :context => @course, :created_at => 1.hour.ago)
      page_view(:user => @user, :context => @course, :created_at => 1.hour.ago)
      counts = PageView.counters_by_context_and_hour(@course, @user)
      counts.size.should == 2
      counts.values.sum.should == 5
    end
  end

  # these tests are not shared with the db tests above, because cassandra
  # actually changes the behavior here -- it puts the counts in one-hour
  # buckets instead of 24-hour buckets, to solve the problem of people viewing
  # analytics from different timezones.
  describe ".counters_by_context_and_hour cassandra" do
    it_should_behave_like "analytics cassandra page views"

    before do
      student_in_course(:active_all => true)
    end

    it "should return user page view counts in the course by hour" do
      timewarp = Time.parse('2012-12-26T19:15:00Z')
      Time.stubs(:now).returns(timewarp)
      page_view(:user => @user, :context => @course, :created_at => 2.days.ago)
      page_view(:user => @user, :context => @course, :created_at => 2.days.ago)
      page_view(:user => @user, :context => @course, :created_at => 3.hours.ago)
      page_view(:user => @user, :context => @course, :created_at => 1.hour.ago)
      page_view(:user => @user, :context => @course, :created_at => 1.hour.ago)
      counts = PageView.counters_by_context_and_hour(@course, @user)
      counts.size.should == 3
      counts.values.sum.should == 5
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
      counts.should == { @user1.id => { :page_views => 4, :participations => 3 },
                         @user2.id => { :page_views => 5, :participations => 1 },
      }

      # partial retrieval
      PageView.counters_by_context_for_users(@course, [@user2.id]).should == { @user2.id => counts[@user2.id] }
    end
  end

  describe ".counters_by_context_for_users db" do
    it_should_behave_like ".counters_by_context_for_users"
  end

  describe ".counters_by_context_for_users cassandra" do
    it_should_behave_like ".counters_by_context_for_users"
    it_should_behave_like "analytics cassandra page views"
  end
end
