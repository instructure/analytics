require 'mocha/api'
require 'active_support/core_ext'
require File.expand_path(File.dirname(__FILE__) + '/../../lib/analytics/tardy')

module Analytics
  describe Tardy do
    let(:time1) { Time.utc(2012, 10, 10, 1) } # Oct 10
    let(:time2) { Time.utc(2012, 11, 15, 6) } # Nov 15
    let(:time3) { Time.utc(2012, 12, 12, 9) } # Dec 12

    it "is missing if assignment is past due and there is no submission date" do
      tardy = Tardy.new(time1, nil, time1+1)

      tardy.decision.should == :missing

      tardy.missing?.should  == true
      tardy.late?.should     == false
      tardy.on_time?.should  == false
      tardy.floating?.should == false
    end

    it "is late if assignment is past due and the submission date is thereafter" do
      tardy = Tardy.new(time1, time2, time1+1)

      tardy.decision.should == :late

      tardy.missing?.should  == false
      tardy.late?.should     == true
      tardy.on_time?.should  == false
      tardy.floating?.should == false
    end

    it "is on time (1) if assignment is past due, and submission date occurs beforehand" do
      tardy = Tardy.new(time2, time1, time3)

      tardy.decision.should == :on_time

      tardy.missing?.should  == false
      tardy.late?.should     == false
      tardy.on_time?.should  == true
      tardy.floating?.should == false
    end

    it "is on time (2) if assignment has no due date, but submission date exists" do
      tardy = Tardy.new(nil, time1, time1)

      tardy.decision.should == :on_time

      tardy.missing?.should  == false
      tardy.late?.should     == false
      tardy.on_time?.should  == true
      tardy.floating?.should == false
    end

    it "is floating if not submitted and assignment is unscheduled (no due date)" do
      tardy = Tardy.new(nil, nil, time1)

      tardy.decision.should == :floating

      tardy.missing?.should  == false
      tardy.late?.should     == false
      tardy.on_time?.should  == false
      tardy.floating?.should == true
    end

    it "memoizes @decision even if not explicitly called" do
      tardy = Tardy.new(nil, time1, time1)
      tardy.on_time?.should == true
    end
  end
end
