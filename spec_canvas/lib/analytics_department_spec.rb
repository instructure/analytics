# encoding: utf-8

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
require_relative '../spec_helper'

describe Analytics::Department do

  before :each do
    @account = Account.default
    @account.sub_accounts.create!(name: "Some department")
    @account.sub_accounts.create!(name: "Some other department")
    account_admin_user

    @acct_statistics = Analytics::Department.new(@user, @account, @account.default_enrollment_term, "current")
  end

  describe "account level statistics" do
    it "should return number of subaccounts" do
      expect(@acct_statistics.statistics[:subaccounts]).to eq 2
      expect(@acct_statistics.statistics_by_subaccount.size).to eq 3
    end

    it "should return the number of courses, across all subaccounts" do
      course_shim(account: @account, active_course: true)
      course_shim(account: @account.sub_accounts.first, active_course: true)
      expect(@acct_statistics.statistics[:courses]).to eq 2
    end

    it "should not count courses that are crosslisted" do
      c1 = course_shim(account: @account.sub_accounts.first, active_all: true)
      c2 = course_shim(account: @account.sub_accounts.second, active_all: true)
      c2.course_sections.create!({ :name => "section 2" })
      c2.course_sections.first.crosslist_to_course(c1)
      lst = @acct_statistics.statistics_by_subaccount.sort_by{|x| x[:id]}
      expect(lst[0][:courses]).to eq 0
      expect(lst[1][:courses]).to eq 1
      expect(lst[2][:courses]).to eq 1
    end

    it "should return the number of courses, grouped by subaccount" do
      course_shim(account: @account, active_course: true)
      course_shim(account: @account.sub_accounts.first, active_course: true)
      course_shim(account: @account.sub_accounts.second, active_course: true)
      course_shim(account: @account.sub_accounts.second, active_course: true)
      lst = @acct_statistics.statistics_by_subaccount.sort_by{|x| x[:id]}
      expect(lst[0][:courses]).to eq 1
      expect(lst[1][:courses]).to eq 1
      expect(lst[2][:courses]).to eq 2
    end

    it "should return the number of teachers and students, across all subaccounts" do
      c1 = course_shim(account: @account, active_all: true)
      c2 = course_shim(account: @account.sub_accounts.first, active_all: true)
      s1 = student_in_course(course: c1, active_all: true).user
      student_in_course(course: c2, active_all: true)
      student_in_course(course: c2, user: s1, active_all: true) # enroll student in both courses
      hsh = @acct_statistics.statistics
      expect(hsh[:teachers]).to eq 2
      expect(hsh[:students]).to eq 2
    end

    it "should return the number of teachers and students, grouped by subaccount" do
      c1 = course_shim(account: @account, active_all: true)
      c2 = course_shim(account: @account.sub_accounts.first, active_all: true)
      c3 = course_shim(account: @account.sub_accounts.second, active_all: true)
      c4 = course_shim(account: @account.sub_accounts.second, active_all: true)
      student_in_course(course: c1, active_all: true)
      student_in_course(course: c2, active_all: true)
      student_in_course(course: c3, active_all: true)
      3.times do
        student_in_course(course: c4, active_all: true)
      end
      lst = @acct_statistics.statistics_by_subaccount.sort_by{|x| x[:id]}
      expect(lst[0][:teachers]).to eq 1
      expect(lst[1][:teachers]).to eq 1
      expect(lst[2][:teachers]).to eq 2
      expect(lst[0][:students]).to eq 1
      expect(lst[1][:students]).to eq 1
      expect(lst[2][:students]).to eq 4 # 1 for c3, 3 for c4
    end
  end

  context "#calculate_and_clamp_dates" do
    ## Use Case Grid
    #
    # start_at | end_at     | result                    | comments
    # -------- | ---------- | ------------------------- | --------
    # ≤ end_at | ≤ now      | [start_at, end_at]        | nominal past term
    # ≤ now    | > now      | [start_at, now]           | nominal ongoing term
    # > now    | ≥ start_at | [now, now]                | nominal future term
    # ≤ now    | < start_at | [start_at, start_at]      | past or current term with dates out-of-order
    # > now    | < start_at | [now, now]                | future term with dates out-of-order
    # ≤ now    | none       | [start_at, now]           | ongoing term with indefinite end
    # > now    | none       | [now, now]                | future term with indefinite end
    # none     | ≤ now      | [end_at - 1.year, end_at] | past term with indefinite start
    # none     | > now      | [now - 1.year, now]       | ongoing term with indefinite start
    # none     | none       | [now - 1.year, now]       | ongoing term with indefinite start or end

    let!(:now){ Time.zone.now }

    before do
      allow(@acct_statistics).to receive(:slaved).and_return(nil)
    end

    def check_clamps(start_at, end_at, expected_start_at = nil, expected_end_at = nil)
      expected_start_at ||= start_at
      expected_end_at ||= end_at

      Timecop.freeze(now) do
        start_at, end_at = @acct_statistics.send(:calculate_and_clamp_dates, start_at, end_at, nil)

        expect(start_at).to eq expected_start_at
        expect(end_at).to eq expected_end_at
      end
    end

    it "start_at ≤ end_at | end_at ≤ now" do
      check_clamps(6.months.ago, 3.months.ago)
    end

    it "start_at ≤ now | end_at > now" do
      start_at = 3.months.ago
      end_at = 3.months.from_now

      check_clamps(start_at, end_at, start_at, now)
      check_clamps(now, end_at, now, now)
    end

    it "start_at > now | end_at ≥ start_at" do
      start_at = 3.months.from_now
      end_at = 6.months.from_now

      check_clamps(start_at, end_at, now, now)
      check_clamps(start_at, start_at, now, now)
    end

    it "start_at ≤ now | end_at < start_at" do
      start_at = 3.months.ago
      end_at = 6.months.ago

      check_clamps(start_at, end_at, start_at, start_at)
      check_clamps(now, end_at, now, now)
    end

    it "start_at > now | end_at < start_at" do
      check_clamps(6.months.from_now, 3.months.from_now, now, now)
    end

    it "start_at ≤ now | end_at = nil" do
      check_clamps(3.months.ago, nil, nil, now)
      check_clamps(now, nil, now, now)
    end

    it "start_at > now | end_at = nil" do
      check_clamps(3.months.from_now, nil, now, now)
    end

    it "start_at = nil | end_at ≤ now" do
      end_at = 3.months.ago
      check_clamps(nil, end_at, end_at - 1.year)
      check_clamps(nil, now, now - 1.year, now)
    end

    it "start_at = nil | end_at > now" do
      check_clamps(nil, 3.months.from_now, now - 1.year, now)
    end

    it "start_at = nil | end_at = nil" do
      check_clamps(nil, nil, now - 1.year, now)
    end
  end
end
