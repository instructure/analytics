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
