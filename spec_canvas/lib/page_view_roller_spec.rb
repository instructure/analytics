require File.expand_path(File.dirname(__FILE__) + '/../../../../../spec/spec_helper')

describe PageViewRoller do
  def build_page_view(opts={})
    context = opts[:context] || @course
    user = opts[:user] || @user

    page_view = page_view_model(
      :context => context,
      :user => user,
      :controller => opts[:controller])

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
      access.display_name = 'Some Asset'
      needs_save = true
    end

    page_view.save if needs_save
    page_view
  end

  before :each do
    @course = course_model
    @user = user_model
  end

  describe "#start_day" do
    it "should return nil with no page views" do
      PageViewRoller.start_day.should be_nil
    end

    it "should not include page_views without a non-course context" do
      build_page_view(:context => Account.default)
      PageViewRoller.start_day.should be_nil
    end

    it "should not include summarized page_views" do
      build_page_view(:summarized => true)
      PageViewRoller.start_day.should be_nil
    end

    it "should return the earliest page_view's created_at"  do
      date1 = Date.today - 1.day
      date2 = Date.today - 2.days
      [date1, date2].each{ |date| build_page_view(:created_at => date) }
      PageViewRoller.start_day.should == date2
    end
  end

  describe "#end_day" do
    it "should return nil with no page views" do
      PageViewRoller.end_day.should be_nil
    end

    it "should not include page_views without a non-course context" do
      build_page_view(:context => Account.default)
      PageViewRoller.end_day.should be_nil
    end

    it "should not include summarized page_views" do
      build_page_view
      PageViewRoller.end_day.should be_nil
    end

    it "should return the latest page_view's created_at"  do
      date1 = Date.today - 1.day
      date2 = Date.today - 2.days
      [date1, date2].each{ |date| build_page_view(:created_at => date) }
      PageViewRoller.end_day.should == date1
    end

    it "should ignore page_views before overridden start_day"  do
      today = Date.today
      date = today - 1.day
      build_page_view(:created_at => date)
      PageViewRoller.end_day(:start_day => today - 2.days).should == date
      PageViewRoller.end_day(:start_day => today).should == today
    end
  end

  describe "#rollup_one" do
    it "should bin page views on that day" do
      date = Date.today
      build_page_view(:created_at => date)
      build_page_view(:created_at => date)
      PageViewsRollup.expects(:augment!).with(@course.id, date, 'other', 2, 0).once
      PageViewRoller.rollup_one(date)
    end

    it "should only bin page views on that day" do
      date = Date.today
      build_page_view(:created_at => date)
      PageViewsRollup.expects(:augment!).never
      PageViewRoller.rollup_one(date - 1.day)
    end

    it "should bin by course" do
      first_course = @course
      second_course = course_model
      date = Date.today
      build_page_view(:context => first_course, :created_at => date)
      build_page_view(:context => first_course, :created_at => date)
      build_page_view(:context => second_course, :created_at => date)
      PageViewsRollup.expects(:augment!).with(first_course.id, date, 'other', 2, 0).once
      PageViewsRollup.expects(:augment!).with(second_course.id, date, 'other', 1, 0).once
      PageViewRoller.rollup_one(date)
    end

    it "should bin by category" do
      date = Date.today
      build_page_view(:controller => 'gradebooks', :created_at => date)
      build_page_view(:controller => 'discussion_topics', :created_at => date)
      build_page_view(:controller => 'discussion_topics', :created_at => date)
      PageViewsRollup.expects(:augment!).with(@course.id, date, 'grades', 1, 0).once
      PageViewsRollup.expects(:augment!).with(@course.id, date, 'discussions', 2, 0).once
      PageViewRoller.rollup_one(date)
    end

    it "should recognize participations" do
      date = Date.today
      build_page_view(:participated => true, :created_at => date)
      PageViewsRollup.expects(:augment!).with(@course.id, date, 'other', 1, 1).once
      PageViewRoller.rollup_one(date)
    end

    it "should mark the rolled up views as summarized" do
      date = Date.today
      page_view1 = build_page_view(:created_at => date)
      page_view2 = build_page_view(:created_at => date)
      PageViewRoller.rollup_one(date)
      page_view1.reload.should be_summarized
      page_view2.reload.should be_summarized
    end
  end

  describe "#rollup_all" do
    it "should rollup each day between start and end in reverse order" do
      start_day = Date.today - 4.days
      end_day = Date.today
      PageViewRoller.stubs(:start_day).returns(start_day)
      PageViewRoller.stubs(:end_day).returns(end_day)
      seq = sequence('reverse chronological')
      (start_day..end_day).reverse_each do |day|
        PageViewRoller.expects(:rollup_one).with(day, anything).in_sequence(seq)
      end
      PageViewRoller.rollup_all
    end
  end
end
