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
require_dependency "analytics/tardiness_breakdown"

module Analytics
  describe TardinessBreakdown do
    describe 'defaults' do
      subject { TardinessBreakdown.new(nil,nil,nil) }

      describe '#missing' do
        subject { super().missing }
        it { is_expected.to eq 0 }
      end

      describe '#late' do
        subject { super().late }
        it { is_expected.to eq 0 }
      end

      describe '#on_time' do
        subject { super().on_time }
        it { is_expected.to eq 0 }
      end

      describe '#floating' do
        subject { super().floating }
        it { is_expected.to eq 0 }
      end

      describe '#total' do
        subject { super().total }
        it { is_expected.to eq 0 }
      end
    end

    describe 'in common usage' do
      let(:breakdown) { TardinessBreakdown.new(12, 8, 3, 2) }

      it 'should return total count' do
        expect(breakdown.total).to eq 25
      end

      it 'can be output as a hash' do
        expect(breakdown.as_hash).to eq({
          :missing  => 12,
          :late     => 8,
          :on_time  => 3,
          :floating => 2,
          :total    => 25
        })
      end

      it 'formats as a scaled hash' do
        expect(breakdown.as_hash_scaled(10)).to eq({
          :missing  => 1.2,
          :late     => 0.8,
          :on_time  => 0.3,
          :floating => 0.2,
          :total    => 10
        })
      end

      it 'handles a 0 denominator acceptably' do
        expect(breakdown.as_hash_scaled(0.0)).to eq({
          :missing  => 0.0,
          :late     => 0.0,
          :on_time  => 0.0,
          :floating => 0.0,
          :total    => 0.0
        })
      end
    end
  end
end
