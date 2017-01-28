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

require_relative '../../../../../../spec/spec_helper'
require_dependency "analytics/permitted_course"

module Analytics
  describe PermittedCourse do
    describe '#assignments' do
      let(:analytics) do
        stub('course_analytics',
          assignment_rollups_for: ['SECTIONAL_ROLLUP'],
          assignments: ['ASSIGNMENT_DATA'])
      end

      let(:user) { stub('user') }
      let(:shard) { stub('shard') }
      let(:course) do
        stub('course',
          shard: shard,
          section_visibilities_for: [{course_section_id: 'SECTION_ID1'}],
          course_sections: stub('course_sections',
            active: stub('active_course_sections',
              pluck: ['SECTION_ID1', 'SECTION_ID2'])))
      end
      let(:permitted_course) { PermittedCourse.new(user, course) }

      before do
        Analytics::Course.stubs(:new).returns(analytics)
        shard.stubs(:activate).yields
      end

      it 'uses the full rollups when visibility level is full' do
        course.stubs(:enrollment_visibility_level_for).returns(:full)
        expect(permitted_course.assignments_uncached).to eq ['SECTIONAL_ROLLUP']
      end

      it 'uses tallied rollups for section visibility' do
        course.stubs(:enrollment_visibility_level_for).returns(:sections)
        expect(permitted_course.assignments_uncached).to eq ['SECTIONAL_ROLLUP']
      end

      it 'includes all sections for full visibility users regardless of enrollments' do
        course.stubs(:enrollment_visibility_level_for).returns(:full)
        analytics.expects(:assignment_rollups_for).with(['SECTION_ID1', 'SECTION_ID2'])
        permitted_course.assignments_uncached
      end

      it 'limits to visible sections for section visibility users' do
        course.stubs(:enrollment_visibility_level_for).returns(:sections)
        analytics.expects(:assignment_rollups_for).with(['SECTION_ID1'])
        permitted_course.assignments_uncached
      end

      it 'tallys assignments for direct visibility' do
        course.stubs(:enrollment_visibility_level_for).returns(:users)
        expect(permitted_course.assignments_uncached).to eq ['ASSIGNMENT_DATA']
      end
    end

    describe "async" do
      let(:permitted_course) { PermittedCourse.new(user_factory, course_shim) }

      it "reads and saves the data if available in cache" do
        permitted_course.expects(:assignments_uncached).never
        Rails.cache.expects(:read).once.returns("data")
        expect(permitted_course.async_data_available?).to eq true
        expect(permitted_course.assignments).to eq "data"
      end

      it "kicks off a background job when creating the Progress model" do
        enable_cache do
          progress = permitted_course.progress_for_background_assignments
          expect(permitted_course.async_data_available?).to eq false
          # returns the same progress again
          expect(permitted_course.progress_for_background_assignments).to eq progress
          run_jobs
          expect(permitted_course.async_data_available?).to eq true
          expect(permitted_course.progress_for_background_assignments).to eq progress
        end
      end

      it "rejects the existing Progress model if the cache has been evicted" do
        progress = permitted_course.progress_for_background_assignments
        progress.start!
        progress.complete!
        expect(permitted_course.progress_for_background_assignments).not_to eq progress
      end

      it "unifies cache check between rails3 and rails4" do
        enable_cache do
          assignments = [{id: 1}]
          Rails.cache.write(permitted_course.assignments_cache_key, assignments, :use_new_rails => false)
          expect(permitted_course.async_data_available?).to be_truthy
        end
      end

      it "unifies cache lookup between rails3 and rails4" do
        enable_cache do
          assignments = [{id: 1}]
          Rails.cache.write(permitted_course.assignments_cache_key, assignments, :use_new_rails => false)
          expect(permitted_course.assignments).to eq assignments
        end
      end
    end
  end
end
