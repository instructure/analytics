require File.expand_path('../../../../../../spec/spec_helper', File.dirname(__FILE__))
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
        permitted_course.assignments_uncached.should == ['SECTIONAL_ROLLUP']
      end

      it 'uses tallied rollups for section visibility' do
        course.stubs(:enrollment_visibility_level_for).returns(:sections)
        permitted_course.assignments_uncached.should == ['SECTIONAL_ROLLUP']
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
        permitted_course.assignments_uncached.should == ['ASSIGNMENT_DATA']
      end
    end

    describe "async" do
      let(:permitted_course) { PermittedCourse.new(user, course) }

      it "reads and saves the data if available in cache" do
        permitted_course.expects(:assignments_uncached).never
        Rails.cache.expects(:read).once.returns("data")
        permitted_course.async_data_available?.should == true
        permitted_course.assignments.should == "data"
      end

      it "kicks off a background job when creating the Progress model" do
        enable_cache do
          progress = permitted_course.progress_for_background_assignments
          permitted_course.async_data_available?.should == false
          # returns the same progress again
          permitted_course.progress_for_background_assignments.should == progress
          run_jobs
          permitted_course.async_data_available?.should == true
          permitted_course.progress_for_background_assignments.should == progress
        end
      end

      it "rejects the existing Progress model if the cache has been evicted" do
        progress = permitted_course.progress_for_background_assignments
        progress.start!
        progress.complete!
        permitted_course.progress_for_background_assignments.should_not == progress
      end
    end
  end
end
