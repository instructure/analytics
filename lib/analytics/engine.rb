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

module Analytics
  class Engine < ::Rails::Engine
    config.autoload_paths << File.expand_path(File.join(__FILE__, "../.."))

    # runs once on process startup, both development and production
    initializer "analytics.canvas_plugin" do
      AccountServices.register_service :analytics,
        :name => "Analytics",
        :description => "",
        :expose_to_ui => :setting,
        :default => false

      Permissions.register :view_analytics,
        :label => lambda { I18n.t('#role_override.permissions.view_analytics', "View analytics pages") },
        :available_to => %w(AccountAdmin TaEnrollment TeacherEnrollment StudentEnrollment AccountMembership),
        :true_for => %w(AccountAdmin TaEnrollment TeacherEnrollment)
    end

    Autoextend.hook(:PageView, :"Analytics::Extensions::PageView",
                    method: :prepend)
    Autoextend.hook(:"PageView::Pv4Client",
                    :"Analytics::Extensions::PageView::Pv4Client")

    # runs once in production, but on each request (to match class reloading)
    # in development with class_caching off
    config.to_prepare do
      require 'analytics/extensions/courses_controller'
      require 'analytics/extensions/custom_sidebar_links_helper'
      require 'analytics/extensions/course'
      require 'analytics/extensions/enrollment'
      require 'analytics/extensions/grade_calculator'
      require 'analytics/extensions/permissions'
      require 'analytics/extensions/user'
    end
  end
end
