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

module Analytics::Extensions::PageView
  def self.prepended(klass)
    klass.extend Analytics::PageViewIndex
  end

  def category
    category = read_attribute(:category)
    if !category && read_attribute(:controller)
      category = CONTROLLER_TO_ACTION[controller.downcase.to_sym]
    end
    category || :other
  end

  def store
    self.summarized = true
    result = super
    if context_id && context_type == 'Course'
      PageViewsRollup.increment!(context_id, created_at, category, participated && asset_user_access)
    end
    result
  end

  # this is kind of terrible, but PageView::EventStream isn't assigned yet,
  # and there's no direct hook to capture the later constant assignment
  # so hook the creation of the stream, and add our hooks then
  module EventStreamExtension
    def initialize(&block)
      super(&block)
      if table == 'page_views'
        on_insert do |page_view|
          Analytics::PageViewIndex::EventStream.update(page_view, true)
        end

        on_update do |page_view|
          Analytics::PageViewIndex::EventStream.update(page_view, false)
        end
      end
    end
  end
  ::EventStream::Stream.prepend(EventStreamExtension)

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
