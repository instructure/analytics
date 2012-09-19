require File.expand_path(File.dirname(__FILE__) + '/../../../../../spec/spec_helper')

describe Analytics::StudentInCourse do
  describe "#enrollment" do
    it "should not cache the enrollment" do
      course_with_teacher(:active_all => 1)
      student_in_course(:course => @course, :active_all => 1)
      enable_cache do
        analytics1 = Analytics::StudentInCourse.new(@teacher, nil, @course, @student)
        analytics2 = Analytics::StudentInCourse.new(@teacher, nil, @course, @student)
        analytics1.enrollment.object_id.should_not == analytics2.enrollment.object_id
      end
    end
  end
end
