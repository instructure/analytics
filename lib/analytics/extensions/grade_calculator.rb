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

GradeCalculator.class_eval do
  # after recomputing current scores on enrollments in the course, recache its
  # grade distribution
  def save_scores_with_cached_grade_distribution
    save_scores_without_cached_grade_distribution
    unless @current_updates.empty? && @final_updates.empty?
      @course.recache_grade_distribution
    end
  end
  alias_method_chain :save_scores, :cached_grade_distribution
end
