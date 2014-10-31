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

require File.expand_path('../../../../../../lib/stats', File.dirname(__FILE__))
require File.expand_path('../../../lib/rollups/score_buckets', File.dirname(__FILE__))
module Rollups
  describe ScoreBuckets do
    let(:points) { 100 }
    let(:buckets) { ScoreBuckets.new(points) }

    describe 'defaults' do
      it 'defaults all array values to 0' do
        expect(buckets.to_a.size).to eq ScoreBuckets::BUCKET_COUNT
        expect(buckets.to_a.select{|i| i != 0}.size).to eq 0
      end

      it 'sets a low number of buckets to the same number as the points' do
        small_buckets = ScoreBuckets.new(5)
        expect(small_buckets.to_a.size).to eq 5
      end
    end

    describe '#<<' do
      it 'adds a termial low value to the lowest bucket' do
        buckets << 0
        expect(buckets.to_a[0]).to eq 1
      end

      it 'adds a terminally high value to the top bucket' do
        buckets << points
        expect(buckets.to_a[ScoreBuckets::BUCKET_COUNT - 1]).to eq 1
      end

      it 'adds an impossibly high value to the top bucket' do
        buckets << (points * 2)
        expect(buckets.to_a[ScoreBuckets::BUCKET_COUNT - 1]).to eq 1
      end

      it 'places values in buckets evenly' do
        buckets << (points / 2)
        expect(buckets.to_a[ScoreBuckets::BUCKET_COUNT / 2]).to eq 1
      end

      describe 'stat counting' do
        before { buckets << 1 << 2 << 3 << 50 << 98 << 99 << 100 }

        subject { buckets }

        describe '#max' do
          subject { super().max }
          it { is_expected.to eq 100 }
        end

        describe '#min' do
          subject { super().min }
          it { is_expected.to eq 1 }
        end

        describe '#first_quartile' do
          subject { super().first_quartile }
          it { is_expected.to eq 2 }
        end

        describe '#third_quartile' do
          subject { super().third_quartile }
          it { is_expected.to eq 99 }
        end

        describe '#median' do
          subject { super().median }
          it { is_expected.to eq 50 }
        end
      end

      describe 'stat counting on small buckets' do
        let(:buckets) { ScoreBuckets.new(5) }
        before { buckets << 1 << 1 << 2<< 5 <<3 << 2<< 1 }
        subject { buckets }

        describe '#max' do
          subject { super().max }
          it { is_expected.to eq 5 }
        end

        describe '#min' do
          subject { super().min }
          it { is_expected.to eq 1 }
        end

        describe '#first_quartile' do
          subject { super().first_quartile }
          it { is_expected.to eq 1.0 }
        end

        describe '#third_quartile' do
          subject { super().third_quartile }
          it { is_expected.to eq 3 }
        end

        describe '#median' do
          subject { super().median }
          it { is_expected.to eq 2 }
        end
      end
    end

    describe '#index_for' do
      it 'picks the top bucket for the max value' do
        expect(buckets.index_for(points)).to eq ScoreBuckets::BUCKET_COUNT - 1
      end

      it 'places the boundary value for the first bucket in the second bucket' do
        boundary_value  = (points / ScoreBuckets::BUCKET_COUNT)
        expect(buckets.index_for(boundary_value)).to eq 1
      end

      it 'reverts to a boundary value if the number of points available is strange' do
        tiny_buckets = ScoreBuckets.new(1.5)
        expect(tiny_buckets.index_for(1)).to eq 0
      end
    end

    describe '.parse' do
      describe 'with good data' do
        let(:scores) { [0, 5, 2,0,0,0,0,0,0,4,0,1,2,1,0,0,0,0,0,7,9,3,10,1,0] }
        let(:buckets) { ScoreBuckets.parse(100, scores) }
        subject { buckets }

        describe '#max' do
          subject { super().max }
          it { is_expected.to eq 94 }
        end

        describe '#min' do
          subject { super().min }
          it { is_expected.to eq 6 }
        end

        describe '#median' do
          subject { super().median }
          it { is_expected.to eq 82.0 }
        end
      end

      it 'errors when you dont have a points total' do
        expect { ScoreBuckets.parse(nil, []) }.to raise_error(ArgumentError)
      end
    end

    describe 'a bucket with 0 points possible' do
      let(:buckets) { ScoreBuckets.new(0) }

      before do
        buckets << 1 << 2 << 3 << 4 << 5
      end

      it 'builds a single array bucket' do
        expect(buckets.to_a).to eq [5]
      end

      it 'calculates 0 as all indexes' do
        (1..5).each do |value|
          expect(buckets.index_for(value)).to eq 0
        end
      end

      subject { buckets }

      describe '#max' do
        subject { super().max }
        it { is_expected.to eq 5 }
      end

      describe '#min' do
        subject { super().min }
        it { is_expected.to eq 1 }
      end

      describe '#first_quartile' do
        subject { super().first_quartile }
        it { is_expected.to eq 1.5 }
      end

      describe '#third_quartile' do
        subject { super().third_quartile }
        it { is_expected.to eq 4.5 }
      end

      describe '#median' do
        subject { super().median }
        it { is_expected.to eq 3 }
      end
    end
  end
end
