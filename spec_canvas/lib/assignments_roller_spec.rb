
require File.expand_path(File.dirname(__FILE__) + '/../../../../../spec/spec_helper')

describe AssignmentsRoller do
  it "creates rollups for current assignments" do
    AssignmentRollup.delete_all
    this_course = course
    this_assignment = course.assignments.create!
    Course.active.count.should_not == 0
    AssignmentsRoller.rollup_all
    AssignmentRollup.all.count.should_not == 0
  end
end
