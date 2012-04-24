module Analytics
  module Participation
    # required of host: page_view_scope

    def page_views
      @page_views ||= slaved do
        page_views = {}
        page_view_scope.find(:all,
          :select => "DATE(created_at) AS day, controller, COUNT(*) AS ct",
          :group => "DATE(created_at), controller").each do |row|
          day = row.day
          action = controller_to_action(row.controller)
          count = row.ct.to_i
          page_views[day] ||= {}
          page_views[day][action] ||= 0
          page_views[day][action] += count
        end
        page_views
      end
    end

    def participations
      @participations ||= slaved do
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

  private

    CONTROLLER_TO_ACTION = {
      :assignments         => :assignments,
      :courses             => :general,
      :quizzes             => :quizzes,
      :wiki_pages          => :pages,
      :gradebooks          => :grades,
      :submissions         => :assignments,
      :discussion_topics   => :discussions,
      :files               => :files,
      :context_modules     => :modules,
      :announcements       => :announcements,
      :collaborations      => :collaborations,
      :conferences         => :conferences,
      :groups              => :groups,
      :question_banks      => :quizzes,
      :gradebook2          => :grades,
      :wiki_page_revisions => :pages,
      :folders             => :files,
      :grading_standards   => :grades,
      :discussion_entries  => :discussions,
      :assignment_groups   => :assignments,
      :quiz_questions      => :quizzes,
      :gradebook_uploads   => :grades
    }

    def controller_to_action(controller)
      return CONTROLLER_TO_ACTION[controller.downcase.to_sym] || :other
    end
  end
end
