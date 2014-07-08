require File.expand_path(File.dirname(__FILE__) + '/../../../../../spec/spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Analytics::Department do
 
  before :each do
    @account = Account.default
    @account.sub_accounts.create!(name: "Some department") 
    account_admin_user

    @acct_statistics = Analytics::Department.new(@user, @account, @account.default_enrollment_term, "current")
  end

  describe "account level statistics" do
    it "should return number of subaccounts" do
      @acct_statistics.statistics[:subaccounts].should == 1
      @acct_statistics.statistics_by_subaccount.size.should == 2
    end

    it "should return the number of courses, across all subaccounts" do
      course(account: @account, active_course: true)
      course(account: @account.sub_accounts.first, active_course: true)
      @acct_statistics.statistics[:courses].should == 2
    end

    it "should return the number of courses, grouped by subaccount" do
      course(account: @account, active_course: true)
      course(account: @account.sub_accounts.first, active_course: true)
      @acct_statistics.statistics_by_subaccount.each { |hsh| hsh[:courses].should == 1 }
    end

    it "should return the number of teachers and students, across all subaccounts" do
      c1 = course(account: @account, active_all: true)
      c2 = course(account: @account.sub_accounts.first, active_all: true)
      student_in_course(course: c1, active_all: true)
      student_in_course(course: c2, active_all: true)
      hsh = @acct_statistics.statistics
      hsh[:teachers].should == 2
      hsh[:students].should == 2

    end

    it "should return the number of teachers and students, grouped by subaccount" do
      c1 = course(account: @account, active_all: true)
      c2 = course(account: @account.sub_accounts.first, active_all: true)
      student_in_course(course: c1, active_all: true)
      student_in_course(course: c2, active_all: true)
      lst = @acct_statistics.statistics_by_subaccount
      lst.each{ |hsh| hsh[:teachers].should == 1 }
      lst.each{ |hsh| hsh[:students].should == 1 }
    end
  end
end
