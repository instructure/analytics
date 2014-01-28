require File.expand_path('../../../../../../spec/spec_helper', File.dirname(__FILE__))

module Analytics
  describe TardinessBreakdown do
    describe 'defaults' do
      subject { TardinessBreakdown.new(nil,nil,nil) }
      its(:missing) { should == 0 }
      its(:late) { should == 0 }
      its(:on_time) { should == 0 }
      its(:floating) { should == 0 }
      its(:total) { should == 0 }
    end

    describe 'in common usage' do
      let(:breakdown) { TardinessBreakdown.new(12, 8, 3, 2) }

      it 'should return total count' do
        breakdown.total.should == 25
      end

      it 'can be output as a hash' do
        breakdown.as_hash.should == {
          :missing  => 12,
          :late     => 8,
          :on_time  => 3,
          :floating => 2,
          :total    => 25
        }
      end

      it 'formats as a scaled hash' do
        breakdown.as_hash_scaled(10).should == {
          :missing  => 1.2,
          :late     => 0.8,
          :on_time  => 0.3,
          :floating => 0.2,
          :total    => 10
        }
      end

      it 'handles a 0 denominator acceptably' do
        breakdown.as_hash_scaled(0.0).should == {
          :missing  => 0.0,
          :late     => 0.0,
          :on_time  => 0.0,
          :floating => 0.0,
          :total    => 0.0
        }
      end
    end
  end
end
