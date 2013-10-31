def page_view(opts={})
  course = opts[:course] || @course
  user = opts[:user] || @student
  controller = opts[:assignments] || 'assignments'
  summarized = opts[:summarized] || nil

  page_view = PageView.new(
    :context => course,
    :user => user,
    :controller => controller)

  page_view.request_id = UUIDSingleton.instance.generate

  if opts[:participated]
    page_view.participated = true
    access = AssetUserAccess.new
    access.context = page_view.context
    access.display_name = 'Some Asset'
    access.action_level = 'participate'
    access.participate_score = 1
    access.user = page_view.user
    access.save!
    page_view.asset_user_access = access
  end

  page_view.store
  page_view
end
