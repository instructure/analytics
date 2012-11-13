require File.expand_path(File.dirname(__FILE__) + '/../../../../../spec/spec_helper')

module Analytics

  describe StudentInCourse do

    describe "#enrollment" do
      it "should not cache the enrollment" do
        course_with_teacher(:active_all => 1)
        student_in_course(:course => @course, :active_all => 1)
        enable_cache do
          analytics1 = StudentInCourse.new(@teacher, nil, @course, @student)
          analytics2 = StudentInCourse.new(@teacher, nil, @course, @student)
          analytics1.enrollment.object_id.should_not == analytics2.enrollment.object_id
        end
      end
    end

    describe '#basic_assignment_hash' do
      let(:due_dates) { (1..6).map{ |i| { :due_at => i.days.from_now } } }
      let(:assignment) { stub_everything(:due_dates_for => [due_dates.first, due_dates], :due_at => 100.days.ago) }

      it 'lets VDD determine the due_at value' do
        blank = stub_everything
        student_in_course = StudentInCourse.new(blank, blank, blank, blank)
        student_in_course.basic_assignment_hash(assignment)[:due_at].should == due_dates.last[:due_at]
      end

    end

  end

end
