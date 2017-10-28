#
# Copyright (C) 2017 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under the
# terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#

module Analytics
  class StudentSummaries
    def initialize(course, page_view_counts)
      @course = course
      @page_view_counts = page_view_counts
      @analysis = @course.page_view_analysis(page_view_counts)
    end

    def for(student)
      StudentSummary.new(student, @course, @page_view_counts, @analysis)
    end
  end
end
