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
  class PageViewAnalysis
    attr_reader :page_view_counts

    def initialize(page_view_counts)
      @page_view_counts = page_view_counts
    end

    def max_participations
      hash[:max_participations]
    end

    def max_page_views
      hash[:max_page_views]
    end

    def hash
      page_view_stats = ::Stats::Counter.new(page_view_counts.values.map { |x| x[:page_views] })
      participation_stats = ::Stats::Counter.new(page_view_counts.values.map { |x| x[:participations] })
      {
        max_page_views: page_view_stats.max,
        page_views_quartiles: page_view_stats.quartiles,
        max_participations: participation_stats.max,
        participations_quartiles: participation_stats.quartiles,
      }
    end
  end
end
