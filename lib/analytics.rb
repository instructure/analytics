class Analytics

  def initialize(current_user)
    @current_user = current_user
  end

  def user_participation(user, courses)
    conditions = courses.map {|c| "(context_id = #{c.id})"}.join(" OR ")
    page_views = {}
    ActiveRecord::Base.connection.execute("SELECT DATE(created_at) AS day, controller, COUNT(*) FROM page_views WHERE context_type = 'Course' AND user_id = #{user.id} AND (#{conditions}) GROUP BY day, controller;").each do |row|
      page_views[row[0]] ||= {}
      page_views[row[0]][row[1]] = row[2].to_i
    end

    return {"page_views" => page_views}
  end

  def course_participation(course, users=[], sections=[])
    conditions = users.map {|u| "(user_id = #{u.id})"}.join(" OR ")
    page_views = {}
    ActiveRecord::Base.connection.execute("SELECT DATE(created_at) AS day, controller, COUNT(*) FROM page_views WHERE context_type = 'Course' AND context_id = #{course.id} AND (#{conditions}) GROUP BY day, controller;").each do |row|
      page_views[row[0]] ||= {}
      page_views[row[0]][row[1]] = row[2].to_i
    end

    return {"page_views" => page_views}
  end

  def start_date(courses, users, sections)
    return Time.now.utc - 30.days
  end

  def end_date(courses, users, sections)
    return Time.now.utc
  end
end
