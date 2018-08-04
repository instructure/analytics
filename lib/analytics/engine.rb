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
    config.paths['lib'].eager_load!

    Autoextend.hook(:AccountServices, after_load: true) do
      AccountServices.register_service :analytics,
                                       :name => "Analytics",
                                       :description => "",
                                       :expose_to_ui => :setting,
                                       :default => false
    end
    Autoextend.hook(:Account,
                    :"Analytics::Extensions::Account",
                    method: :prepend)
    Autoextend.hook(:Course,
                    :"Analytics::Extensions::Course")
    Autoextend.hook(:CoursesController,
                    :"Analytics::Extensions::CoursesController",
                    method: :prepend)
    Autoextend.hook(:CustomSidebarLinksHelper,
                    :"Analytics::Extensions::CustomSidebarLinksHelper",
                    method: :prepend)
    Autoextend.hook(:Enrollment,
                    :"Analytics::Extensions::Enrollment")
    Autoextend.hook(:GradeCalculator,
                    :"Analytics::Extensions::GradeCalculator",
                    method: :prepend)
    Autoextend.hook(:"Loaders::CourseStudentAnalyticsLoader",
                    :"Analytics::Extensions::CourseStudentAnalyticsLoader",
                    method: :prepend)
    Autoextend.hook(:Permissions, after_load: true) do
      ::Permissions.register :view_analytics,
                           :label => lambda { I18n.t('#role_override.permissions.view_analytics', "Analytics - view pages") },
                           :available_to => %w(AccountAdmin TaEnrollment TeacherEnrollment StudentEnrollment AccountMembership),
                           :true_for => %w(AccountAdmin TaEnrollment TeacherEnrollment),
                           :applies_to_concluded => true
    end
    Autoextend.hook(:PageView,
                    :"Analytics::Extensions::PageView",
                    method: :prepend)
    Autoextend.hook(:"PageView::Pv4Client",
                    :"Analytics::Extensions::PageView::Pv4Client")
    Autoextend.hook(:User, :"Analytics::Extensions::User")
  end
end
