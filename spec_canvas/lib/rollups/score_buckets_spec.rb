require File.expand_path('../../../../../../lib/stats', File.dirname(__FILE__))
require File.expand_path('../../../lib/rollups/score_buckets', File.dirname(__FILE__))
module Rollups
  describe ScoreBuckets do
    let(:points) { 100 }
    let(:buckets) { ScoreBuckets.new(points) }

    describe 'defaults' do
      it 'defaults all array values to 0' do
        buckets.to_a.size.should == ScoreBuckets::BUCKET_COUNT
        buckets.to_a.select{|i| i != 0}.size.should == 0
      end

      it 'sets a low number of buckets to the same number as the points' do
        small_buckets = ScoreBuckets.new(5)
        small_buckets.to_a.size.should == 5
      end
    end

    describe '#<<' do
      it 'adds a termial low value to the lowest bucket' do
        buckets << 0
        buckets.to_a[0].should == 1
      end

      it 'adds a terminally high value to the top bucket' do
        buckets << points
        buckets.to_a[ScoreBuckets::BUCKET_COUNT - 1].should == 1
      end

      it 'adds an impossibly high value to the top bucket' do
        buckets << (points * 2)
        buckets.to_a[ScoreBuckets::BUCKET_COUNT - 1].should == 1
      end

      it 'places values in buckets evenly' do
        buckets << (points / 2)
        buckets.to_a[ScoreBuckets::BUCKET_COUNT / 2].should == 1
      end

      describe 'stat counting' do
        before { buckets << 1 << 2 << 3 << 50 << 98 << 99 << 100 }

        subject { buckets }

        its(:max) { should == 100 }
        its(:min) { should == 1 }
        its(:first_quartile) { should == 2 }
        its(:third_quartile) { should == 99 }
        its(:median) { should == 50 }
      end

      describe 'stat counting on small buckets' do
        let(:buckets) { ScoreBuckets.new(5) }
        before { buckets << 1 << 1 << 2<< 5 <<3 << 2<< 1 }
        subject { buckets }

        its(:max) { should == 5 }
        its(:min) { should == 1 }
        its(:first_quartile) { should == 1.0 }
        its(:third_quartile) { should == 3 }
        its(:median) { should == 2 }
      end
    end

    describe '#index_for' do
      it 'picks the top bucket for the max value' do
        buckets.index_for(points).should == ScoreBuckets::BUCKET_COUNT - 1
      end

      it 'places the boundary value for the first bucket in the second bucket' do
        boundary_value  = (points / ScoreBuckets::BUCKET_COUNT)
        buckets.index_for(boundary_value).should == 1
      end

      it 'reverts to a boundary value if the number of points available is strange' do
        tiny_buckets = ScoreBuckets.new(1.5)
        tiny_buckets.index_for(1).should == 0
      end
    end

    describe '.parse' do
      describe 'with good data' do
        let(:scores) { [0, 5, 2,0,0,0,0,0,0,4,0,1,2,1,0,0,0,0,0,7,9,3,10,1,0] }
        let(:buckets) { ScoreBuckets.parse(100, scores) }
        subject { buckets }

        its(:max) { should == 94 }
        its(:min) { should == 6 }
        its(:median) { should == 82.0 }
      end

      it 'errors when you dont have a points total' do
        lambda { ScoreBuckets.parse(nil, []) }.should raise_error(ArgumentError)
      end
    end

    describe 'a bucket with 0 points possible' do
      let(:buckets) { ScoreBuckets.new(0) }

      before do
        buckets << 1 << 2 << 3 << 4 << 5
      end

      it 'builds a single array bucket' do
        buckets.to_a.should == [5]
      end

      it 'calculates 0 as all indexes' do
        (1..5).each do |value|
          buckets.index_for(value).should == 0
        end
      end

      subject { buckets }

      its(:max) { should == 5 }
      its(:min) { should == 1 }
      its(:first_quartile) { should == 1.5 }
      its(:third_quartile) { should == 4.5 }
      its(:median) { should == 3 }
    end
  end
end
