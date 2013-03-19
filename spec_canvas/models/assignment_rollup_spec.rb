require File.expand_path(File.dirname(__FILE__) + '/../../../../../spec/spec_helper')

describe AssignmentRollup do
  let(:rollup) { AssignmentRollup.new }

  describe '.init_with_assignment_and_section' do
    let(:assignment) do
      stub(:id => 1, :title => 'the title', :points_possible => 99, :due_at => Time.now, :muted? => true)
    end

    let(:section) { stub(:id => 2) }
    let(:rollup) { AssignmentRollup.init_with_assignment_and_section(assignment, section) }

    subject { rollup }

    its(:assignment_id) { should == assignment.id }
    its(:course_section_id) { should == section.id }
    its(:muted) { should == assignment.muted? }
    %w{title points_possible due_at}.each do |attr|
      its(attr.to_sym) { should == assignment.send(attr.to_sym) }
    end
  end

  describe '#calculate_scores' do
    let(:scores) { [0,5,10,15,20,25,30,35,40,45,50] }

    let(:submission_scope) do
      scope = stub('sub_scope')
      scope.stubs(:useful_find_each).multiple_yields(*scores.map{|s| [stub(:score => s)] })
      scope
    end

    before { rollup.calculate_scores(50, submission_scope) }
    subject { rollup }

    its(:max_score) { should == 50 }
    its(:min_score) { should == 0 }
    its(:first_quartile_score) { should == 10 }
    its(:median_score) { should == 25 }
    its(:third_quartile_score) { should == 40 }
  end

  describe '#calculate_tardiness' do  38
    let(:student_count) { 100 }
    let(:tardiness_breakdown) { stub('tardiness_breakdown') }
    let(:breakdown_data) { { :late => 10, :missing => 20, :on_time => 30 } }

    before do
      return_data = breakdown_data.merge(breakdown_data){|k,v| v.to_f / student_count.to_f}
      tardiness_breakdown.expects(:as_hash_scaled).with(student_count).returns return_data
      rollup.calculate_tardiness(tardiness_breakdown, student_count)
    end

    subject { rollup }

    its(:total_submissions) { should == student_count }
    its(:late_submissions) { should == 0.1 }
    its(:missing_submissions) { should == 0.2 }
    its(:on_time_submissions) { should == 0.3 }
  end

  describe '.init' do
    let(:this_course) { course }
    let(:assignment) { Assignment.create!(:context => this_course, :due_at => 28.hours.from_now) }
    let(:section) { this_course.course_sections.create! }
    let(:submission_scope) { Submission.scoped(:conditions => {:id => 0}) }

    before do
      AssignmentRollup.delete_all
      AssignmentRollup.init(assignment, section, submission_scope, 0)
    end

    it 'does not create more than 1 rollup for the same assignment/section' do
      2.times do
        AssignmentRollup.init(assignment, section, submission_scope, 0)
      end
      AssignmentRollup.all.count.should == 1
    end

    it 'keeps the due_at as a data type that can support time information' do
      due_at = AssignmentRollup.last.due_at
      due_at.should_not be_a(Date)
      [DateTime, ActiveSupport::TimeWithZone].should include(due_at.class)
    end
  end

end
