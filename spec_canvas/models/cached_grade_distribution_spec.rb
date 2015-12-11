#
# Copyright (C) 2014 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

require_relative '../../../../../spec/spec_helper'

describe CachedGradeDistribution do
  describe "#recalculate!" do
    before :each do
      @course = course_model
      @enrollment = student_in_course
      @enrollment.workflow_state = 'active'
      @enrollment.computed_current_score = 12
      @enrollment.save!
      @dist = @course.cached_grade_distribution
    end

    it "should count grades from active student enrollments" do
      @dist.recalculate!
      expect(@dist.s12).to eq 1
    end

    it "should count grades from completed student enrollments" do
      @enrollment.workflow_state = 'completed'
      @enrollment.save!

      @dist.recalculate!
      expect(@dist.s12).to eq 1
    end

    it "should not count grades from invited student enrollments" do
      @enrollment.workflow_state = 'invited'
      @enrollment.save!

      @dist.recalculate!
      expect(@dist.s12).to eq 0
    end

    it "should not count grades from deleted student enrollments" do
      @enrollment.workflow_state = 'deleted'
      @enrollment.save!

      @dist.recalculate!
      expect(@dist.s12).to eq 0
    end

    it "should not count grades from fake student enrollments" do
      @enrollment.type = 'StudentViewEnrollment'
      @enrollment.save!

      @dist.recalculate!
      expect(@dist.s12).to eq 0
    end

    it "should not count grades from teacher enrollments" do
      @enrollment.type = 'TeacherEnrollment'
      @enrollment.save!

      @dist.recalculate!
      expect(@dist.s12).to eq 0
    end

    it "should count same grade only once per student" do
      other_section = @course.course_sections.create!
      @second_enrollment = @course.enroll_student(@student,
        :enrollment_state => 'active',
        :section => other_section,
        :allow_multiple_enrollments => true)
      @second_enrollment.computed_current_score = 12

      @dist.recalculate!
      expect(@dist.s12).to eq 1 # not 2
    end

    it "should zero out scores it doesn't see" do
      @dist.recalculate!
      expect(@dist.s12).to eq 1

      @enrollment.computed_current_score = 11
      @enrollment.save!

      @dist.recalculate!
      expect(@dist.s12).to eq 0
    end

    it "should round scores" do
      @enrollment.computed_current_score = 11.4
      @enrollment.save!

      @dist.recalculate!
      expect(@dist.s11).to eq 1
      expect(@dist.s12).to eq 0

      @enrollment.computed_current_score = 11.6
      @enrollment.save!

      @dist.recalculate!
      expect(@dist.s11).to eq 0
      expect(@dist.s12).to eq 1
    end
  end

  describe "triggers" do
    before :each do
      @course = course_model
      @dist = @course.create_cached_grade_distribution
      @course.any_instantiation.stubs(:cached_grade_distribution).returns(@dist)
    end

    it "should get recalculated when a student enrollment is added" do
      @dist.expects(:recalculate!).once
      student_in_course
    end

    it "should get recalculated when a student enrollment's workflow_state is changed" do
      @enrollment = student_in_course

      @dist.expects(:recalculate!).once
      @enrollment.workflow_state = 'deleted'
      @enrollment.save
    end

    it "should not get recalculated when a fake student enrollment is added" do
      @dist.expects(:recalculate!).never
      @course.student_view_student
    end

    it "should not get recalculated when a fake student enrollment's workflow_state is changed" do
      @course.student_view_student
      @enrollment = @course.student_view_enrollments.first

      @dist.expects(:recalculate!).never
      @enrollment.workflow_state = 'deleted'
      @enrollment.save
    end

    it "should get recalculated after non-empty GradeCalculator.recompute_final_score" do
      student_in_course

      @dist.expects(:recalculate!).once
      GradeCalculator.recompute_final_score([@student.id], @course.id)
    end

    it "should not get recalculated after empty GradeCalculator.recompute_final_score" do
      # no-op because there are no enrollments in the course
      @dist.expects(:recalculate!).never
      GradeCalculator.recompute_final_score([], @course.id)
    end
  end
end
