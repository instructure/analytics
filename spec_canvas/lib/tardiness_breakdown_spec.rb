require 'mocha_standalone'
require 'active_support/core_ext'
require File.expand_path(File.dirname(__FILE__) +
          '/../../lib/analytics/tardiness_breakdown')

module Analytics

  describe TardinessBreakdown do

    let(:breakdown) { TardinessBreakdown.new(12, 8, 3) }

    it "initializes" do
      x = TardinessBreakdown.new
      x.should be_a(TardinessBreakdown)

      x.missing.should == 0
      x.late.should    == 0
      x.on_time.should == 0
    end

    it "formats as a hash" do
      breakdown.as_hash.should == {
        :missing => 12,
        :late    => 8,
        :on_time => 3
      }
    end

    it "formats as a scaled hash" do
      breakdown.as_hash_scaled(10).should == {
        :missing => 1.2,
        :late    => 0.8,
        :on_time => 0.3
      }
    end
  end

end