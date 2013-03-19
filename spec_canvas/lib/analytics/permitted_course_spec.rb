require File.expand_path('../../../../../../spec/spec_helper', File.dirname(__FILE__))
module Analytics
  describe PermittedCourse do
    describe '#assignments' do
      let(:analytics) do
        stub('course_analytics', {
          :assignment_rollups => ['FULL_ROLLUP'],
          :assignment_rollups_for => ['SECTIONAL_ROLLUP'],
          :assignments => ['ASSIGNMENT_DATA']
        })
      end

      let(:user) { stub('user') }
      let(:shard) { stub('shard') }
      let(:course) { stub('course', :shard => shard, :section_visibilities_for => []) }
      let(:permitted_course) { PermittedCourse.new(user, course, analytics) }

      before do
        shard.stubs(:activate).yields
      end

      it 'uses the full rollups when visibility level is full' do
        course.stubs(:enrollment_visibility_level_for).returns(:full)
        permitted_course.assignments.should == ['FULL_ROLLUP']
      end

      it 'uses tallied rollups for section visibility' do
        course.stubs(:enrollment_visibility_level_for).returns(:sections)
        permitted_course.assignments.should == ['SECTIONAL_ROLLUP']
      end

      it 'tallys assignments for direct visibility' do
        course.stubs(:enrollment_visibility_level_for).returns(:users)
        permitted_course.assignments.should == ['ASSIGNMENT_DATA']
      end
    end
  end
end
