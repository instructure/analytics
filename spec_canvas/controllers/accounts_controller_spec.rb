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

# This file is part of the analytics engine

require_relative '../../../../../spec/spec_helper'

describe AccountsController, :type => :controller do
  ROLE = 'TestAdmin'

  before :once do
    @account = Account.default
    @account.allowed_services = '+analytics'
    @account.save!

    role = custom_account_role(ROLE, :account => @account)
    RoleOverride.manage_role_override(@account, role, 'read_course_list', :override => true)
    RoleOverride.manage_role_override(@account, role, 'view_analytics', :override => true)

    @admin = account_admin_user(:account => @account, :role => role, :active_all => true)
  end

  before :each do
    user_session(@admin)
  end

  context "permissions" do
    def expect_injection
      get 'show', :id => @account.id, :format => 'html'
      expect(controller.account_custom_links.map { |link| link[:url] }).to include "/accounts/#{@account.id}/analytics"
    end

    def forbid_injection
      get 'show', :id => @account.id, :format => 'html'
      expect(controller.account_custom_links.map { |link| link[:url] }).not_to include "/accounts/#{@account.id}/analytics"
    end

    it "should inject an analytics button on the account page under nominal conditions" do
      expect_injection
    end

    it "should not inject an analytics button on the account page when analytics is disabled" do
      @account.allowed_services = '-analytics'
      @account.save!
      forbid_injection
    end

    it "should not inject an analytics button on the account page without the analytics permission" do
      RoleOverride.manage_role_override(@account, ROLE, 'view_analytics', :override => false)
      forbid_injection
    end
  end
end
