module Analytics

  class TardinessGridCoord
    attr_reader :assignment_id, :student_id

    def initialize(assignment_id, student_id)
      raise ArgumentError if assignment_id.nil?
      @assignment_id, @student_id = assignment_id, student_id
    end

    def hash
      [@assignment_id, @student_id].hash
    end

    def eql?(other)
      @assignment_id == other.assignment_id &&
        @student_id == other.student_id
    end
  end
  #
  # TardinessGrid is the in-between place for assignment/submission
  # tardiness data that comes from the DB, but has not yet been broken
  # down into tardiness buckets.
  #
  # Imagine a 2D grid with assignments on the Y axis and students
  # on the X axis. Each square represents a submission that is either
  # missing, late or turned in on time. We tally each square by row
  # (assignment) or by column (student) to get a TardinessBreakdown
  # object at the end.
  #
  class TardinessGrid
    attr_reader :assignments, :students, :submissions, :tardies_memo

    # 'assignments' is a list of Assignment objects
    # 'submissions' is a list of Submission objects, and must have a user
    # 'now'  is primarily used for testing, but it is a parameter that
    #        can be passed in if you want to tally as if "now" were
    #        some time in the future or the past.
    def initialize(assignments, students, submissions, now=Time.zone.now)
      @assignments, @students, @submissions, @now =
       assignments,  students,  submissions,  now
      # Use assignment.id as key for Hash
      @assignments_by_id = TardinessGrid.lookup_table(assignments)
      @students_by_id = TardinessGrid.lookup_table(students)
      @tardies_memo = {}
    end

    # Converts an array of objects with ids into a hash indexed by their ids.
    def self.lookup_table(array)
      Hash[*array.map{ |item| [item.id, item] }.flatten]
    end

    def prebuild
      @assignments.each do |assignment|
        @students.each do |student|
          coord = TardinessGridCoord.new(assignment.id, student.id)
          submission = get_submission(coord)
          @tardies_memo[coord] = build_tardy(assignment, student, submission)
        end
      end
      self
    end

    def get_assignment(assignment_id)
      @assignments_by_id[assignment_id]
    end

    def get_student(student_id)
      @students_by_id[student_id]
    end

    def get_submission(coord)
      return nil unless submissions_by_student_id.has_key? coord.student_id
      submissions_by_student_id[coord.student_id].detect do |submission|
        submission.assignment_id == coord.assignment_id
      end
    end

    def get_tardy(assignment_id, student_id)
      coord = TardinessGridCoord.new(assignment_id, student_id)
      @tardies_memo[coord] ||= build_tardy_from_coord(coord)
    end

    def build_tardy_from_coord(coord)
      assignment = get_assignment(coord.assignment_id)
      student    = get_student(coord.student_id)
      submission = get_submission(coord)

      build_tardy(assignment, student, submission)
    end

    def build_tardy(assignment, student, submission)
      asd = AssignmentSubmissionDate.new(assignment, student, submission)
      Tardy.new(asd.due_date, asd.submission_date, @now)
    end

    def build_tardiness_breakdown(missing, late, on_time)
      TardinessBreakdown.new(missing, late, on_time)
    end

    def submissions_by_student_id
      @submissions_by_student_id ||=
        submissions.group_by{ |s| s.user_id }
    end

    def submissions_by_assignment_id
      @submissions_by_assignment_id ||=
        submissions.group_by{ |s| s.assignment_id }
    end

    # could make a generator for the following 2 methods, or possibly
    # classes as suggested by jon: https://gist.github.com/4219039

    def tardies_for_student(student_id)
      raise ArgumentError, "Student ID #{student_id} not found" \
        unless @students_by_id.has_key? student_id

      @assignments.map do |assignment|
        get_tardy(assignment.id, student_id)
      end
    end

    def tardies_for_assignment(assignment_id)
      raise ArgumentError, "Assignment ID #{assignment_id} not found" \
        unless @assignments_by_id.has_key? assignment_id

      @students.map do |student|
        get_tardy(assignment_id, student.id)
      end
    end

    # 'type' is either :student or :assignment
    # 'id'   is either a student_id or an assignment_id
    def tally(type, id)
      missing, late, on_time = 0, 0, 0
      send("tardies_for_#{type}", id).each do |tardy|
        missing += 1 if tardy.missing?
        late    += 1 if tardy.late?
        on_time += 1 if tardy.on_time?
      end
      build_tardiness_breakdown(missing, late, on_time)
    end
  end
end