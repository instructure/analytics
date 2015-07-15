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

def page_view(opts={})
  course = opts[:course] || @course
  user = opts[:user] || @student
  controller = opts[:assignments] || 'assignments'
  summarized = opts[:summarized] || nil

  page_view = PageView.new(
    :context => course,
    :user => user,
    :controller => controller)

  page_view.request_id = SecureRandom.uuid

  if opts[:participated]
    page_view.participated = true
    access = AssetUserAccess.new
    access.context = page_view.context
    access.display_name = 'Some Asset'
    access.action_level = 'participate'
    access.participate_score = 1
    access.user = page_view.user
    access.save!
    page_view.asset_user_access = access
  end

  page_view.store
  page_view
end

module CourseShim
  def course_shim(*args)
    if defined?(course_factory)
      course_factory(*args)
    else
      course(*args)
    end
  end
end

RSpec.configure do |config|
  config.include CourseShim
end
