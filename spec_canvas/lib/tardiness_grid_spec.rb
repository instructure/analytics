require 'mocha_standalone'
require 'active_support/core_ext'
require File.expand_path(File.dirname(__FILE__) +
          '/../../lib/analytics/tardiness_grid')

module Analytics
  describe TardinessGrid do

    # Tardiness Grid Test Data:
    # ============================
    #          A1: S1 --
    #          A2: S2 S3
    #          A3: -- --
    #              .. ..
    #              U1 U2
    #
    # Legend:
    # A = Assignment
    # S = Submission
    # U = User ("Student")

    let(:assignment1) { stub('assignment1', :id => 1, :to_ary => nil) }
    let(:assignment2) { stub('assignment2', :id => 2, :to_ary => nil) }
    let(:assignment3) { stub('assignment3', :id => 3, :to_ary => nil) }

    let(:student1) { stub('student1', :id => 1) }
    let(:student2) { stub('student2', :id => 2) }

    let(:submission1) { stub('submission1',
                          :id => 1,
                          :assignment_id => 1,
                          :user_id => student1.id) }
    let(:submission2) { stub('submission2',
                          :id => 2,
                          :assignment_id => 2,
                          :user_id => student1.id) }
    let(:submission3) { stub('submission3',
                          :id => 3,
                          :assignment_id => 2,
                          :user_id => student2.id) }

    let(:now) { Time.now }

    let(:grid) do
      TardinessGrid.new(
        [assignment1, assignment2, assignment3],
        [student1, student2],
        [submission1, submission2, submission3],
        now
      )
    end

    it "initializes" do
      x = TardinessGrid.new([], [], [], now)
      x.should be_a(TardinessGrid)

      x.assignments.size.should == 0
      x.students.size.should == 0
      x.submissions.size.should == 0
    end

    describe "::lookup_table helper method" do
      class HasID < Struct.new(:id); end

      it "converts an empty array into an empty hash" do
        table = TardinessGrid.lookup_table([])
        table.should == {}
      end

      it "converts a collection with ids to a hash lookup table" do
        objs = [one=HasID.new(1), two=HasID.new(2), three=HasID.new(3)]
        table = TardinessGrid.lookup_table(objs)
        table.should == {1 => one, 2 => two, 3 => three}
      end
    end

    describe "#submissions_by_student_id" do
      it "groups submissions by student id" do
        grid.submissions_by_student_id.should == {
          1 => [submission1, submission2],
          2 => [submission3]
        }
      end

      it "memoizes the result" do
        grid.submissions.expects(:group_by).returns(:something).once
        2.times{ grid.submissions_by_student_id.should_not be_nil }
      end
    end

    describe "#submissions_by_assignment_id" do
      it "groups submissions by assignment id" do
        grid.submissions_by_assignment_id.should == {
          1 => [submission1],
          2 => [submission2, submission3]
        }
      end

      it "memoizes the result" do
        grid.submissions.expects(:group_by).returns(:something).once
        2.times{ grid.submissions_by_assignment_id.should_not be_nil }
      end
    end

    describe "tardy iteration" do
      before do
        # Override the build_tardy method so we don't need to depend on
        # the AssignmentSubmissionDate or Tardy classes being there.
        def grid.build_tardy(assignment, student, submission)
          return [assignment, student, submission]
        end
      end

      describe "#tardies_for_student" do
        it "uses correct assignments and submissions" do
          grid.tardies_for_student(1).should ==
            [
              [assignment1, student1, submission1],
              [assignment2, student1, submission2],
              [assignment3, student1, nil]
            ]
          grid.tardies_for_student(2).should ==
            [
              [assignment1, student2, nil],
              [assignment2, student2, submission3],
              [assignment3, student2, nil]
            ]
        end

        it "raises ArgumentError if student id not found" do
          expect { grid.tardies_for_student(100) }.to \
            raise_error(ArgumentError)
        end
      end

      describe "#tardies_for_assignment" do
        it "uses correct assignments and submissions" do
          grid.tardies_for_assignment(1).should ==
            [
              [assignment1, student1, submission1],
              [assignment1, student2, nil]
            ]
          grid.tardies_for_assignment(2).should ==
            [
              [assignment2, student1, submission2],
              [assignment2, student2, submission3]
            ]
          grid.tardies_for_assignment(3).should ==
            [
              [assignment3, student1, nil],
              [assignment3, student2, nil]
            ]
        end

        it "raises ArgumentError if assignment id not found" do
          expect { grid.tardies_for_assignment(100) }.to \
            raise_error(ArgumentError)
        end
      end

      describe "#prebuild" do
        def tgc(assignment, student)
          TardinessGridCoord.new(assignment.id, student.id)
        end

        it "has the same Tardy objects as when not pre-populated" do
          memo = grid.prebuild.tardies_memo
          grid.instance_variable_set("@tardies_memo", {})

          memo.each_pair do |coord, tardy|
            tardy.should == grid.build_tardy_from_coord(coord)
          end
        end

        it "builds all of the Tardy objects in memory" do
          # For the purposes of this test, we don't care if there are *actual*
          # Tardy objects, just that the values passed would have created
          # Tardy objects in memory as expected.
          grid.prebuild
          grid.tardies_memo.should == {
            tgc(assignment1, student1) => [assignment1, student1, submission1],
            tgc(assignment1, student2) => [assignment1, student2, nil],
            tgc(assignment2, student1) => [assignment2, student1, submission2],
            tgc(assignment2, student2) => [assignment2, student2, submission3],
            tgc(assignment3, student1) => [assignment3, student1, nil],
            tgc(assignment3, student2) => [assignment3, student2, nil]
          }
        end
      end
    end

    describe "#tally" do
      before do
        # Override the build_tardiness_breakdown method so we don't need
        # to depend on TardinessBreakdown class being there.
        def grid.build_tardiness_breakdown(missing, late, on_time)
          return [missing, late, on_time]
        end
      end

      it "accepts :student type" do
        grid.expects(:tardies_for_student).returns([]).once
        grid.tally(:student, 1).should == [0,0,0]
      end

      it "accepts :assignment type" do
        grid.expects(:tardies_for_assignment).returns([]).once
        grid.tally(:assignment, 1).should == [0,0,0]
      end

      it "tallies things" do
        tardies = [
          stub(:missing? => false, :late? => false, :on_time? => true),
          stub(:missing? => false, :late? => true,  :on_time? => false),
          stub(:missing? => true,  :late? => false, :on_time? => false),
          stub(:missing? => true,  :late? => false, :on_time? => false)
        ]
        grid.expects(:tardies_for_assignment).returns(tardies).once
        grid.tally(:assignment, 1).should == [2, 1, 1]
      end
    end
  end
end
