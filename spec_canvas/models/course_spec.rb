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

describe Course do
  describe "#recache_grade_distribution" do
    before :each do
      @course = course_model
      @enrollment = student_in_course
      @enrollment.workflow_state = 'active'
      @enrollment.scores.create!(current_score: 12)
      @enrollment.save!
    end

    it "should create the distribution row if not there yet" do
      @course.cached_grade_distribution.destroy
      @course.reload.recache_grade_distribution
      expect(@course.reload.cached_grade_distribution).not_to be_nil
    end

    it "should update the existing distribution row if any" do
      @course.recache_grade_distribution
      existing = @course.cached_grade_distribution
      expect(existing.s11).to eq 0
      expect(existing.s12).to eq 1

      @enrollment.find_score.update!(current_score: 11)
      @enrollment.save!

      @course.reload.recache_grade_distribution
      expect(@course.cached_grade_distribution).to eq existing
      existing.reload

      expect(existing.s11).to eq 1
      expect(existing.s12).to eq 0
    end
  end
end
