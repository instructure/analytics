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
  class StudentSummary
    def initialize(student, course, page_view_counts, analysis)
      @student = student
      @page_view_counts = page_view_counts
      @analysis = analysis
      @course = course
    end

    def as_hash
      page_views = self.page_views
      participations = self.participations

      {
        :id => @student.id,
        :page_views => page_views[:total],
        :max_page_views => page_views[:max],
        :page_views_level => page_views[:level],
        :participations => participations[:total],
        :max_participations => participations[:max],
        :participations_level => participations[:level],
        :tardiness_breakdown => tardiness_breakdown,
      }
    end

    def page_views
      views_or_participations(:page_views)
    end

    def participations
      views_or_participations(:participations)
    end

    def views_or_participations(type)
      counts = @page_view_counts[@student.id] || {}
      total = counts[type]
      quartiles = @analysis[:"#{type}_quartiles"]

      {
        total: total,
        max: @analysis[:"max_#{type}"],
        level: level(total, quartiles)
      }
    end

    def tardiness_breakdown
      @course.tardiness_breakdowns[:students][@student.id].as_hash
    end

    def level(n, quartiles)
      first, mean, third = quartiles

      if n.nil? || n.zero?
        0
      elsif n < first
        1
      elsif n < third
        2
      else
        3
      end
    end
  end
end
