require 'mocha/api'
require File.expand_path('../../lib/analytics/page_view_analysis', File.dirname(__FILE__))

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
      specify { hash.should_not be_nil }
      specify { hash[:max_page_views].should == 10 }
      specify { hash[:max_participations].should == 32 }

      it 'memoizes the hash' do
        analysis.expects(:page_view_counts).once.returns({})
        analysis.hash
        analysis.hash
        analysis.hash
      end
    end

    describe '#max_page_views' do
      it 'pulls from the hash' do
        analysis.max_page_views.should == 10
      end

      it 'does the same thing with #max_participations' do
        analysis.max_participations.should == 32
      end
    end

  end
end
