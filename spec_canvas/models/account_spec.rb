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

describe Account do
  ROLE = 'TestAdmin'

  before :once do
    @account = Account.default
    @account.allowed_services = '+analytics'
    @account.save!

    @role = custom_account_role(ROLE, :account => @account)
    RoleOverride.manage_role_override(@account, @role, 'read_course_list', :override => true)
    RoleOverride.manage_role_override(@account, @role, 'view_analytics', :override => true)

    @admin = account_admin_user(:account => @account, :role => @role, :active_all => true)
  end

  let(:analytics_tab_opts) {
    {:label=>"Analytics", :css_class=>"analytics_plugin", :href=>:analytics_department_path}
  }

  context "Analytics Tab" do

    it "should inject an analytics tab under nominal conditions" do
      expect(@account.tabs_available(@admin)[-2]).to include(analytics_tab_opts)
    end

    it "should inject an analytics tab for a sub-account" do
      sub_account = @account.sub_accounts.create!
      expect(sub_account.tabs_available(@admin)[-2]).to include(analytics_tab_opts)
    end

    it "should not inject an analytics tab when analytics is disabled" do
      @account.allowed_services = '-analytics'
      @account.save!
      expect(@account.tabs_available(@admin)[-2]).not_to include(analytics_tab_opts)
    end

    it "should not inject an analytics tab without the analytics permission" do
      RoleOverride.manage_role_override(@account, @role, 'view_analytics', :override => false)
      expect(@account.tabs_available(@admin)[-2]).not_to include(analytics_tab_opts)
    end
  end
end
