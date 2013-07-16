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
      let(:permitted_course) { PermittedCourse.new(user, course, analytics) }

      before do
        shard.stubs(:activate).yields
      end

      it 'uses the full rollups when visibility level is full' do
        course.stubs(:enrollment_visibility_level_for).returns(:full)
        permitted_course.assignments.should == ['SECTIONAL_ROLLUP']
      end

      it 'uses tallied rollups for section visibility' do
        course.stubs(:enrollment_visibility_level_for).returns(:sections)
        permitted_course.assignments.should == ['SECTIONAL_ROLLUP']
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
        permitted_course.assignments.should == ['ASSIGNMENT_DATA']
      end
    end
  end
end
