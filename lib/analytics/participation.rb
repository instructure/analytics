module Analytics
  module Participation
    # required of host: page_view_scope

    def page_views
      slaved(:cache_as => :page_views) do
        page_views = {}
        page_view_scope.find(:all,
          :select => "DATE(created_at) AS day, controller, COUNT(*) AS ct",
          :group => "DATE(created_at), controller").each do |row|
          day = row.day
          category = row.category
          count = row.ct.to_i
          page_views[day] ||= {}
          page_views[day][category] ||= 0
          page_views[day][category] += count
        end
        page_views
      end
    end

    def participations
      slaved(:cache_as => :participations) do
        foo = {}
        page_view_scope.find(:all,
          :select => "page_views.created_at, page_views.url, asset_user_accesses.asset_code, asset_user_accesses.asset_category",
          :include => :asset_user_access,
          :conditions => "page_views.participated AND page_views.asset_user_access_id IS NOT NULL").map do |participation|

          foo[participation.asset_user_access_id] ||= {}
          foo[participation.asset_user_access_id][participation.url] ||= {
            :created_at => participation.created_at,
            :url => participation.url,
            :asset_code => participation.asset_user_access.asset_code,
            :asset_category => participation.asset_user_access.asset_category
          }
        end
        foo.map{ |_,bin| bin.map{ |_,hash| hash } }.flatten
      end
    end
  end
end
