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

require_relative '../../lib/analytics/page_view_analysis'
require_dependency "analytics/page_view_analysis"

module Analytics
  describe PageViewAnalysis do

    let(:page_view_counts) do
      {
        'User 1' => { :page_views => 2, :participations => 4 },
        'User 2' => { :page_views => 4, :participations => 16 },
        'User 3' => { :page_views => 6, :participations => 32 },
        'User 4' => { :page_views => 8, :participations => 8 },
        'User 5' => { :page_views => 10, :participations => 2 }
      }
    end

    let(:analysis) { PageViewAnalysis.new( page_view_counts ) }
    let(:hash) { analysis.hash }

    describe '#hash' do
      specify { expect(hash).not_to be_nil }
      specify { expect(hash[:max_page_views]).to eq 10 }
      specify { expect(hash[:page_views_quartiles]).to eq [3, 6, 9] }
      specify { expect(hash[:max_participations]).to eq 32 }
      specify { expect(hash[:participations_quartiles]).to eq [3, 8, 24] }
    end

    describe '#max_page_views' do
      it 'pulls from the hash' do
        expect(analysis.max_page_views).to eq 10
      end

      it 'does the same thing with #max_participations' do
        expect(analysis.max_participations).to eq 32
      end
    end

  end
end
