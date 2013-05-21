require File.expand_path('../../../../../../spec/spec_helper', File.dirname(__FILE__))
module Rollups

  describe AssignmentRollupAggregate do

    let(:rollup_attrs) { {
        :assignment_id => Assignment.create!(:context=>the_course).id,
        :title => 'Some Assignment',
        :course_section_id => CourseSection.create!(:course => the_course).id,
        :max_score => 100,
        :min_score => 0,
        :first_quartile_score => 25,
        :median_score => 50,
        :third_quartile_score => 75,
        :points_possible => 100,
        :score_buckets => [1,0,0,0,0,0,1,1,0,0,0,0,1,0,0,0,0,1,1,0,0,0,0,0,1],
        :total_submissions => 7,
        :on_time_submissions => 4.0 / 7.0,
        :late_submissions => 2.0 / 7.0,
        :missing_submissions => 1.0 / 7.0
      }
    }

    let(:the_course) { course }
    let(:rollup) { AssignmentRollup.new(rollup_attrs) }

    describe 'data from a single rollup' do
      let(:aggregate) { AssignmentRollupAggregate.new([rollup]) }
      let(:data) { aggregate.data }

      describe 'scores' do
        it 'keeps the max/min from the rollup' do
          data[:max_score].should == rollup.max_score
          data[:min_score].should == rollup.min_score
        end

        it 'gets the quartiles from the buckets' do
          data[:first_quartile].should == 26
          data[:median].should == rollup.median_score
          data[:third_quartile].should == 74
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
          data[:max_score].should == 100
          data[:min_score].should == 0
        end

        it 'gets the quartiles from the buckets' do
          data[:first_quartile].should == 29
          data[:median].should == 38
          data[:third_quartile].should == 47
        end
      end

      it 'has the assignment id and name' do
        data[:assignment_id].should == rollup_attrs[:assignment_id]
        data[:title].should == rollup_attrs[:title]
      end

    end
  end

end
