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

      it 'tallys assignments for direct visibility' do
        course.stubs(:enrollment_visibility_level_for).returns(:users)
        permitted_course.assignments.should == ['ASSIGNMENT_DATA']
      end
    end
  end
end
