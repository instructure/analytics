require File.expand_path('../../../../../../spec/spec_helper', File.dirname(__FILE__))

module Analytics
  describe TardinessBreakdown do
    describe '.init_with_scope' do
      let(:assignment) do
        ::Assignment.create!({
          :context => ::Course.create!
        })
      end

      before do
        late_submission = assignment.submissions.create!(:user => ::User.create!)
        on_time_submission = assignment.submissions.create!(:user => ::User.create!)
        ::Submission.where(:id => late_submission).update_all(:cached_due_date => 2.days.ago, :submitted_at => 1.day.ago)
        ::Submission.where(:id => on_time_submission).update_all(:cached_due_date => 1.day.ago, :submitted_at => 2.days.ago)
      end

      subject { TardinessBreakdown.init_with_scope(assignment.submissions, 3) }

      its(:missing) { should == 1 }
      its(:on_time) { should == 1 }
      its(:late) { should == 1 }
    end

    describe 'defaults' do
      subject { TardinessBreakdown.new(nil,nil,nil) }
      its(:missing) { should == 0 }
      its(:late) { should == 0 }
      its(:on_time) { should == 0 }
    end

    describe 'in common usage' do
      let(:breakdown) { TardinessBreakdown.new(12, 8, 3) }

      it 'can be output as a hash' do
        breakdown.as_hash.should == {
          :missing => 12,
          :late    => 8,
          :on_time => 3
        }
      end

      it 'formats as a scaled hash' do
        breakdown.as_hash_scaled(10).should == {
          :missing => 1.2,
          :late    => 0.8,
          :on_time => 0.3
        }
      end

      it 'handles a 0 denominator acceptably' do
        breakdown.as_hash_scaled(0.0).should == {
          :missing => 0.0, :late => 0.0, :on_time => 0.0
        }
      end
    end
  end
end
