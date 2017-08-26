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

require_relative '../../../../../../../spec/spec_helper'
require_dependency "analytics/rollups/assignment_rollup_aggregate"

module Analytics
module Rollups

  describe AssignmentRollupAggregate do

    let(:rollup_attrs) { {
        :assignment_id => Assignment.create!(:context=>the_course).id,
        :title => 'Some Assignment',
        :course_section_id => CourseSection.create!(:course => the_course).id,
        :max_score => 100,
        :min_score => 0,
        :first_quartile_score => 25,
        :median_score => 48.0,
        :third_quartile_score => 75,
        :points_possible => 100,
        :score_buckets => [1,0,0,0,0,0,1,1,0,0,0,0,1,0,0,0,0,1,1,0,0,0,0,0,1],
        :total_submissions => 7,
        :on_time_submissions => 4.0 / 7.0,
        :late_submissions => 2.0 / 7.0,
        :missing_submissions => 1.0 / 7.0
      }
    }

    let(:the_course) { course_shim }
    let(:rollup) { AssignmentRollup.new(rollup_attrs) }

    describe 'data from a single rollup' do
      let(:aggregate) { AssignmentRollupAggregate.new([rollup]) }
      let(:data) { aggregate.data }

      describe 'scores' do
        it 'keeps the max/min from the rollup' do
          expect(data[:max_score]).to eq rollup.max_score
          expect(data[:min_score]).to eq rollup.min_score
        end

        it 'gets the quartiles from the buckets' do
          expect(data[:first_quartile]).to eq 24.0
          expect(data[:median]).to eq rollup.median_score
          expect(data[:third_quartile]).to eq 72.0
        end
      end

      it 'keeps the tardiness breakdown from the rollup' do
      end

      it 'uses the same assignment info as the rollup' do
      end
    end

    describe 'aggregating rollups' do

      let(:rollup1) { AssignmentRollup.new(rollup_attrs.merge({
        :max_score => 32,
        :min_score => 6,
        :first_quartile_score => 9,
        :median_score => 16,
        :third_quartile_score => 30,
        :score_buckets => [0,2,0,0,0,0,5,1,2,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
      })) }

      let(:rollup2) { AssignmentRollup.new(rollup_attrs.merge({
        :max_score => 62,
        :min_score => 30,
        :first_quartile_score => 35,
        :median_score => 40,
        :third_quartile_score => 45,
        :score_buckets => [0,0,0,0,0,0,0,2,2,4,6,1,1,2,1,1,0,0,0,0,0,0,0,0,0],
      })) }

      let(:rollup3) { AssignmentRollup.new(rollup_attrs) }
      let(:aggregate) { AssignmentRollupAggregate.new([rollup1, rollup2, rollup3]) }
      let(:data) { aggregate.data }

      describe 'scores' do
        it 'finds the real max min' do
          expect(data[:max_score]).to eq 100
          expect(data[:min_score]).to eq 0
        end

        it 'gets the quartiles from the buckets' do
          expect(data[:first_quartile]).to eq 27.0
          expect(data[:median]).to eq 36.0
          expect(data[:third_quartile]).to eq 45.0
        end
      end

      it 'has the assignment id and name' do
        expect(data[:assignment_id]).to eq rollup_attrs[:assignment_id]
        expect(data[:title]).to eq rollup_attrs[:title]
      end

    end
  end

end
end
