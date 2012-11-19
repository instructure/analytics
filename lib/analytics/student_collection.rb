module Analytics
  class StudentCollection < PaginatedCollection::Proxy
    attr_reader :sort_strategy, :formatter

    def initialize(scope)
      @sort_strategy = SortStrategy::Default.new
      super proc{ |pager|
        pager = Analytics::Slave.slaved{ @sort_strategy.paginate(scope, pager) }
        pager.map!{ |student| @formatter.call(student) } if @formatter
        pager
      }
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
          @direction == :descending ?
            "enrollments.computed_current_score DESC, users.id DESC" :
            "enrollments.computed_current_score ASC, users.id ASC"
        end

        def paginate(scope, pager)
          super scope.scoped(:order => order), pager
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
          paged_ids = @sorted_ids[(pager.current_page - 1) * pager.per_page, pager.per_page]
          paged_students = scope.scoped(:conditions => {:id => paged_ids})
          student_map = paged_students.inject({}) { |h,student| h[student.id] = student; h }
          pager.replace paged_ids.map{ |id| student_map[id] }
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
