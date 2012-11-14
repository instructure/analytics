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
        def paginate(scope, pager)
          scope.paginate(:page => pager.current_page, :per_page => pager.per_page)
        end
      end

      class ByName < Default
        def paginate(scope, pager)
          super scope.order_by_sortable_name, pager
        end
      end

      class ByScore < Default
        def paginate(scope, pager)
          super scope.scoped(:order => "enrollments.computed_current_score"), pager
        end
      end

      class BySortedIDs
        attr_reader :sorted_ids

        def initialize(sorted_ids)
          @sorted_ids = sorted_ids
        end

        def paginate(scope, pager)
          paged_ids = @sorted_ids[(pager.current_page - 1) * pager.per_page, pager.per_page]
          paged_students = scope.scoped(:conditions => {:id => paged_ids})
          student_map = paged_students.inject({}) { |h,student| h[student.id] = student; h }
          pager.replace paged_ids.map{ |id| student_map[id] }
        end
      end

      class ByPageViews < BySortedIDs
        def initialize(page_view_counts)
          super page_view_counts.keys.sort_by{ |id| [page_view_counts[id][:page_views], id] }
        end
      end

      class ByParticipations < BySortedIDs
        def initialize(page_view_counts)
          super page_view_counts.keys.sort_by{ |id| [page_view_counts[id][:participations], id] }
        end
      end

      KNOWN_STRATEGIES = [:name, :score, :participations, :page_views]
      DEFAULT_STRATEGY = :name

      def self.for(strategy, options={})
        # normalize sort method
        strategy = nil unless KNOWN_STRATEGIES.include?(strategy)
        strategy ||= DEFAULT_STRATEGY
        case strategy
        when :name           then ByName.new
        when :score          then ByScore.new
        when :participations then ByParticipations.new(options[:page_view_counts])
        when :page_views     then ByPageViews.new(options[:page_view_counts])
        end
      end
    end
  end
end
