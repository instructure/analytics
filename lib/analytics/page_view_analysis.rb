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
      @hash ||= page_view_counts.inject({ :max_page_views => 0, :max_participations => 0 }) do |hsh, (id, counts)|
        page_views = counts[:page_views]
        participations = counts[:participations]
        hsh[:max_page_views] = page_views if hsh[:max_page_views] < page_views
        hsh[:max_participations] = participations if hsh[:max_participations] < participations
        hsh
      end
    end
  end
end
