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
  class StudentCollection
    attr_reader :sort_strategy, :formatter

    def initialize(scope)
      @sort_strategy = SortStrategy::Default.new
      @formatter = nil
      @collection = PaginatedCollection.build do |pager|
        pager = Analytics::Slave.slaved{ @sort_strategy.paginate(scope, pager) }
        pager.map!{ |student| @formatter.call(student) } if @formatter
        pager
      end
    end

    def paginate(options = {})
      @collection.paginate(options)
    end

    def sort_by(sort_column, options={})
      @sort_strategy = SortStrategy.for(sort_column, options)
    end

    def format(&formatter)
      @formatter = formatter
    end

    module SortStrategy
      class Default
        attr_reader :direction

        def initialize(direction=:ascending)
          @direction = direction
        end

        def paginate(scope, pager)
          scope.paginate(:page => pager.current_page, :per_page => pager.per_page)
        end
      end

      class ByName < Default
        def paginate(scope, pager)
          super scope.order_by_sortable_name(:direction => @direction), pager
        end
      end

      class ByScore < Default
        def order
          if @direction == :descending
            "scores.current_score DESC NULLS LAST, users.id DESC"
          else
            "scores.current_score ASC NULLS FIRST, users.id ASC"
          end
        end

        def paginate(scope, pager)
          super scope.order(order), pager
        end
      end

      class BySortedIDs
        attr_reader :sorted_ids, :direction

        def initialize(sorted_ids, direction=:ascending)
          @sorted_ids = sorted_ids
          @direction = direction
          @sorted_ids.reverse! if @direction == :descending
        end

        def paginate(scope, pager)
          set_pages(pager)
          offset = (pager.current_page - 1) * pager.per_page
          raise Folio::InvalidPage if pager.current_page < 1
          raise Folio::InvalidPage if pager.current_page > 1 && offset >= @sorted_ids.size
          paged_ids = @sorted_ids[offset, pager.per_page]
          student_map = scope.where(:id => paged_ids).index_by(&:id)
          pager.replace paged_ids.map{ |id| student_map[id] }.compact
        end

        def set_pages(pager)
          pager.current_page = (pager.current_page || 1).to_i
          pager.previous_page = pager.current_page > 1 ? pager.current_page - 1 : nil
          pager.next_page = pager.current_page * pager.per_page < @sorted_ids.size ? pager.current_page + 1 : nil
          pager.total_entries = (@sorted_ids.size / pager.per_page.to_f).ceil
        end
      end

      class ByPageViews < BySortedIDs
        def initialize(page_view_counts, direction=:ascending)
          sorted_ids = page_view_counts.keys.sort_by{ |id| [page_view_counts[id][:page_views], id] }
          super sorted_ids, direction
        end
      end

      class ByParticipations < BySortedIDs
        def initialize(page_view_counts, direction=:ascending)
          sorted_ids = page_view_counts.keys.sort_by{ |id| [page_view_counts[id][:participations], id] }
          super sorted_ids, direction
        end
      end

      KNOWN_STRATEGIES = [
        :name, :name_ascending, :name_descending,
        :score, :score_ascending, :score_descending,
        :participations, :participations_ascending, :participations_descending,
        :page_views, :page_views_ascending, :page_views_descending
      ]
      DEFAULT_STRATEGY = :name

      def self.for(strategy, options={})
        # normalize sort method
        strategy = strategy.to_sym if strategy.is_a?(String)
        strategy = nil unless KNOWN_STRATEGIES.include?(strategy)
        strategy ||= DEFAULT_STRATEGY
        case strategy
        when :name
          ByName.new
        when :name_ascending
          ByName.new(:ascending)
        when :name_descending
          ByName.new(:descending)
        when :score
          ByScore.new
        when :score_ascending
          ByScore.new(:ascending)
        when :score_descending
          ByScore.new(:descending)
        when :participations
          ByParticipations.new(options[:page_view_counts])
        when :participations_ascending
          ByParticipations.new(options[:page_view_counts], :ascending)
        when :participations_descending
          ByParticipations.new(options[:page_view_counts], :descending)
        when :page_views
          ByPageViews.new(options[:page_view_counts])
        when :page_views_ascending
          ByPageViews.new(options[:page_view_counts], :ascending)
        when :page_views_descending
          ByPageViews.new(options[:page_view_counts], :descending)
        end
      end
    end
  end
end
