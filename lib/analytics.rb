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

  def assignments(course, users)
    results = {}
    turn_around_times = {}
    user_ids = users.map(&:id).to_set

    Assignment.active.find(:all, :include => [:submissions],
        :joins => "LEFT OUTER JOIN submissions ON submissions.assignment_id = assignments.id",
        :conditions => ["assignments.context_type = 'Course' AND assignments.context_id = ?", course.id],
        :order => "assignments.id").each do |assignment|

      scores = Stats::Counter.new
      on_time_count = 0
      late_count = 0
      submission_data = nil

      assignment.submissions.each do |submission|
        scores << submission.score if submission.score

        if assignment.due_date && (submission.submitted_at && submission.submitted_at > assignment.due_date)
          late_count += 1
        else
          on_time_count += 1
        end

        if submission.graded? && submission.submitted_at && submission.graded_at
          days_before_grade = ((submission.graded_at - submission.submitted_at) / 1.day).to_i
          turn_around_times[days_before_grade] ||= 0
          turn_around_times[days_before_grade] += 1
        end

        if user_ids.include?(submission.user_id)
          submission_data = { :score => submission.score, :submitted_at => submission.submitted_at }
        end
      end

      results[assignment.id] = score_stats_to_hash(scores).merge!({
          :on_time_count => on_time_count,
          :late_count => late_count,
          :submission_count => on_time_count + late_count,
          :unlock_at => assignment.unlock_at,
          :due_at => assignment.due_at })

      results[assignment.id][:submission] = submission_data if submission_data
    end

    return { :assignments => results, :turn_around_times => turn_around_times }
  end

  def courses_final_scores(courses, options={})
    course_scores = {}
    user_scores = {}
    all_scores = Stats::Counter.new

    Enrollment.all_student.find(:all, :conditions => {:course_id => courses.map(&:id)}, :order => :course_id).each do |enrollment|
      if enrollment.computed_final_score
        (course_scores[enrollment.course_id] ||= Stats::Counter.new) << enrollment.computed_final_score
        (user_scores[enrollment.user_id] ||= []) << enrollment.computed_final_score if options[:include_individuals]
        all_scores << enrollment.computed_final_score if options[:include_totals]
      end
    end

    course_scores.each do |course_id, stats|
      course_scores[course_id] = score_stats_to_hash(stats, true)
      course_scores[course_id][:course_id] = course_id
    end

    result = { :course_results => course_scores }
    result[:individual_results] = user_scores if options[:include_individuals]
    result[:all_results] = score_stats_to_hash(all_scores, true) if options[:include_totals]
    result
  end

private

  def score_stats_to_hash(stats, include_histogram=false)
    result = {
      :max_score => stats.max,
      :min_score => stats.min,
      :average_score => stats.mean,
      :std_dev_score => stats.standard_deviation
    }
    result[:histogram] = stats.histogram if include_histogram
    result
  end
end
