require File.expand_path(File.dirname(__FILE__) + '/../../../../../spec/spec_helper')

describe PageView do
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

  it "should always flag new page views as summarized" do
    view = page_view_model
    view.should be_summarized
  end

  it "should not automatically summarize existing non-summarized page views on save" do
    # set up unsummarized page view
    view = page_view_model
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

    view = page_view_model(:context => course, :created_at => date)
    PageViewsRollup.bin_for(course, date, 'other').views.should == 1
  end

  it "should assign new page view to bin by utc date" do
    # 2012-06-01 20:00:00 AKDT / 2012-06-02 04:00:00 UTC
    time = Time.zone.parse('2012-06-01 20:00:00-08:00').in_time_zone('Alaska')
    course = course_model
    view = page_view_model(:context => course, :created_at => time)
    PageViewsRollup.bin_for(course, time.to_date, 'other').views.should == 0
    PageViewsRollup.bin_for(course, time.utc.to_date, 'other').views.should == 1
  end
end
