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
require_dependency "analytics/student_in_course"

module Analytics
  describe StudentInCourse do
    before do
      course_with_teacher(:active_all => 1)
      student_in_course(:course => @course, :active_all => 1)
    end

    describe "#enrollment" do
      it "should not cache the enrollment" do
        enable_cache do
          a1 = StudentInCourse.new(@teacher, @course, @student)
          a2 = StudentInCourse.new(@teacher, @course, @student)
          expect(a1.enrollment.object_id).not_to eq a2.enrollment.object_id
        end
      end
    end

    describe "#extended_assignment_data" do
      let(:analytics) { StudentInCourse.new(@teacher, @course, @student) }
      let(:time1) { Time.local(2012, 10, 1) }

      it "has a :submission field" do
        assignment = double('assignment')
        subm = double('subm', :user_id => @student.id, :score => 10, :submitted_at => time1, :missing? => false, :excused? => false)
        data = analytics.extended_assignment_data(assignment, [subm])
        expect(data).to eq({
          :excused => false,
          :submission => {
            :score => 10,
            :submitted_at => time1
          }
        })
      end
    end

    describe '#basic_assignment_data' do
      let(:due_at) { 100.days.ago.change(usec: 0) }
      let(:submitted_at) { 101.days.ago.change(usec: 0) }

      let(:analytics) { StudentInCourse.new(@teacher, @course, @student) }
      let(:assignment) { double('assignment').as_null_object }
      let(:submission) {
        double('submission',
          :assignment_id => assignment.id,
          :assigment => assignment,
          :user_id => @student.id,
          :cached_due_date => due_at,
          :missing? => false,
          :late? => false,
          :submitted_at => submitted_at
        )
      }

      it 'lets overridden_for determine the due_at value' do
        expect(analytics.basic_assignment_data(assignment, [submission])[:due_at]).to eq due_at.change(sec: 0)
      end
    end
  end
end
