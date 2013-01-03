require File.expand_path(File.dirname(__FILE__) + '/../../../../../spec/spec_helper')

module Analytics
  describe StudentInCourse do
    before do
      course_with_teacher(:active_all => 1)
      student_in_course(:course => @course, :active_all => 1)
    end

    describe "#enrollment" do
      it "should not cache the enrollment" do
        enable_cache do
          a1 = StudentInCourse.new(@teacher, nil, @course, @student)
          a2 = StudentInCourse.new(@teacher, nil, @course, @student)
          a1.enrollment.object_id.should_not == a2.enrollment.object_id
        end
      end
    end

    describe "#extended_assignment_data" do
      let(:analytics) { StudentInCourse.new(@teacher, nil, @course, @student) }
      let(:time1) { Time.local(2012, 10, 1) }
      it "has a :submission field" do
        assignment = stub('assignment')
        subm = stub('subm', :user_id => @student.id, :score => 10)
        analytics.stubs(:assignment_submission_date).with(assignment, @student, subm).
          returns(stub('AssignmentSubmissionDate', :submission_date => time1))
        data = analytics.extended_assignment_data(assignment, [subm])
        data.should == {
          :submission => {
            :score => 10,
            :submitted_at => time1
          }
        }
      end
    end

    describe '#basic_assignment_data' do
      let(:due_at) { 100.days.ago }
      let(:assignment) { stub_everything(:overridden_for => mock(:due_at => due_at)) }

      it 'lets overridden_for determine the due_at value' do
        blank = stub_everything
        student_in_course = StudentInCourse.new(blank, blank, blank, blank)
        student_in_course.basic_assignment_data(assignment)[:due_at].should == due_at
      end
    end
  end
end
