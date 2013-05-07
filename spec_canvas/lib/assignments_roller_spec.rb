
require File.expand_path(File.dirname(__FILE__) + '/../../../../../spec/spec_helper')

describe AssignmentsRoller do
  let!(:this_course) { course }
  let!(:assignment) { course.assignments.create!(:points_possible=>10) }

  before do
    AssignmentRollup.delete_all
  end

  describe '.rollup_all' do
    it "creates rollups for current assignments" do
      Course.active.count.should_not == 0
      AssignmentsRoller.rollup_all
      AssignmentRollup.all.count.should_not == 0
    end
  end

  describe '.rollup_one' do
    it 'only rolls up the specified section' do
      user1 = User.create!
      user2 = User.create!
      section1 = course.course_sections.create!
      section2 = course.course_sections.create!
      enrollment1 = course.student_enrollments.create!(:user => user1, :course_section => section1)
      enrollment2 = course.student_enrollments.create!(:user => user2, :course_section => section2)
      Enrollment.where(:id => [enrollment1, enrollment2]).update_all(:workflow_state => 'active')
      submission1 = assignment.submissions.create!(:user => user1, :score => 10)
      submission2 = assignment.submissions.create!(:user => user2, :score => 1)
      AssignmentsRoller.rollup_one(this_course, assignment, section1)
      AssignmentRollup.where(:assignment_id => assignment, :course_section_id => section1).first.min_score.should == 10
    end
  end
end
