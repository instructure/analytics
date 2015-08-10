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

AccountsController.class_eval do
  def show_with_analytics
    # this is a really gross coupling with the implementation of vanilla
    # Account#show, but it seems the best way for now to detect that it
    # unequivocally is rendering the html page (vs. a json response, a
    # redirect, or an "unauthorized")
    show_without_analytics
    return unless @courses

    if analytics_enabled?
      # inject a button to the analytics page for the account
      js_env :ANALYTICS => { 'link' => analytics_department_path(:account_id => @account.id) }
      js_bundle :inject_department_analytics, :plugin => :analytics
      css_bundle :analytics_buttons, :plugin => :analytics
    end

    # continue rendering the page
    render :action => 'show'
  end
  alias_method_chain :show, :analytics

  def statistics_with_analytics
    # this is the only condition that could cause the page not to render.
    # statistics_without_analytics will not necessarily return true on success,
    # since @counts_report may be nil.
    return unless authorized_action(@account, @current_user, :view_statistics)
    statistics_without_analytics

    if analytics_enabled?
      # inject a button to the analytics page for the account
      js_env :ANALYTICS => { 'link' => analytics_department_path(:account_id => @account.id) }
      js_bundle :inject_department_statistics_analytics, :plugin => :analytics
      css_bundle :analytics_buttons, :plugin => :analytics
    end

    # continue rendering the page
    render :action => 'statistics'
  end
  alias_method_chain :statistics, :analytics

  private
  # is the context an account with the necessary conditions to view analytics
  # in the account?
  def analytics_enabled?
    @account.active? && service_enabled?(:analytics) &&
    @account.grants_right?(@current_user, session, :view_analytics)
  end
end
