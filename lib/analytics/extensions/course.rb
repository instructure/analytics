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

module Analytics::Extensions::Course
  def self.included(klass)
    klass.has_one :cached_grade_distribution
    klass.has_many :page_views_rollups

    unless klass.instance_methods.include?(:recache_grade_distribution_without_send_later)
      klass.handle_asynchronously_if_production :recache_grade_distribution,
                                                singleton: proc { |c| "recache_grade_distribution:#{ c.global_id }" },
                                                priority: 30
    end
  end

  def recache_grade_distribution
    distribution = cached_grade_distribution
    return distribution.recalculate! if distribution
    Course.unique_constraint_retry do
      (cached_grade_distribution || build_cached_grade_distribution).recalculate!
    end
  end
end
