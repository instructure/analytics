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

require_dependency 'analytics/page_view_index'

PageView.class_eval do
  def category
    category = read_attribute(:category)
    if !category && read_attribute(:controller)
      category = CONTROLLER_TO_ACTION[controller.downcase.to_sym]
    end
    category || :other
  end

  def store_with_rollup
    self.summarized = true
    result = store_without_rollup
    if context_id && context_type == 'Course'
      PageViewsRollup.increment!(context_id, created_at, category, participated && asset_user_access)
    end
    result
  end
  alias_method_chain :store, :rollup

  extend Analytics::PageViewIndex

  PageView::EventStream.on_insert do |page_view|
    Analytics::PageViewIndex::EventStream.update(page_view, true)
  end

  PageView::EventStream.on_update do |page_view|
    Analytics::PageViewIndex::EventStream.update(page_view, false)
  end

  CONTROLLER_TO_ACTION = {
    :assignments              => :assignments,
    :courses                  => :general,
    :quizzes                  => :quizzes,
    :"quizzes/quizzes"        => :quizzes,
    :"quizzes/quizzes_api"    => :quizzes,
    :wiki_pages               => :pages,
    :gradebooks               => :grades,
    :submissions              => :assignments,
    :discussion_topics        => :discussions,
    :files                    => :files,
    :context_modules          => :modules,
    :announcements            => :announcements,
    :collaborations           => :collaborations,
    :conferences              => :conferences,
    :groups                   => :groups,
    :question_banks           => :quizzes,
    :gradebook2               => :grades,
    :wiki_page_revisions      => :pages,
    :folders                  => :files,
    :grading_standards        => :grades,
    :discussion_entries       => :discussions,
    :assignment_groups        => :assignments,
    :quiz_questions           => :quizzes,
    :"quizzes/quiz_questions" => :quizzes,
    :gradebook_uploads        => :grades
  }
end
