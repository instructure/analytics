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

require_relative '../../../../../spec/spec_helper'
require_relative '../cassandra_spec_helper'

describe Analytics::StudentCollection do
  it "should default sort_strategy to Default" do
    collection = Analytics::StudentCollection.new(User)
    expect(collection.sort_strategy).to be_a(Analytics::StudentCollection::SortStrategy::Default)
  end

  describe "#sort_by" do
    it "should set the sort_strategy" do
      collection = Analytics::StudentCollection.new(User)
      collection.sort_by(:score)
      expect(collection.sort_strategy).to be_a(Analytics::StudentCollection::SortStrategy::ByScore)
    end

    it "should pass along options" do
      id = 5
      page_view_counts = { id => { :page_views => 0, :participations => 0 } }
      collection = Analytics::StudentCollection.new(User)
      collection.sort_by(:page_views, :page_view_counts => page_view_counts)
      expect(collection.sort_strategy.sorted_ids).to eq [id]
    end
  end

  describe "#format" do
    it "should set the formatter" do
      formatter = proc{}
      collection = Analytics::StudentCollection.new(User)
      collection.format(&formatter)
      expect(collection.formatter).to eq formatter
    end
  end

  describe "#paginate" do
    before :each do
      @course = Course.create! # no teacher, please
      @enrollments = Array.new(3) { student_in_course(:active_all => true) }
      @users = @enrollments.map(&:user)
      # hide fixtures
      User.where.not(:id => @users).update_all(workflow_state: 'deleted')
    end

    it "should paginate values from the initial scope" do
      collection = Analytics::StudentCollection.new(User.active)
      students = collection.paginate(:page => 1, :per_page => 3)
      expect(students.map(&:id).sort).to eq @users.map(&:id).sort
    end

    it "should use the specified sort strategy" do
      collection = Analytics::StudentCollection.new(User.active)
      collection.sort_by(:page_views, :page_view_counts => {
        @users[0].id => { :page_views => 40, :participations => 10 },
        @users[1].id => { :page_views => 20, :participations => 10 },
        @users[2].id => { :page_views => 60, :participations => 10 },
      })
      students = collection.paginate(:page => 1, :per_page => 3)
      expect(students).to eq [1, 0, 2].map{ |i| @users[i] }
    end

    it "should pass the results through the formatter" do
      collection = Analytics::StudentCollection.new(User.active)
      collection.format { "formatted" }
      students = collection.paginate(:page => 1, :per_page => 3)
      expect(students).to eq Array.new(3) { "formatted" }
    end
  end

  describe 'sort strategies' do
    let(:enrollment_count) { 3 }
    before :each do
      @course = Course.create! # no teacher, please
      @enrollments = Array.new(enrollment_count) { student_in_course(:active_all => true) }
      @users = @enrollments.map(&:user)
      # hide fixtures
      User.where.not(:id => @users).update_all(workflow_state: 'deleted')
      @pager = PaginatedCollection::Collection.new
      @pager.current_page = 1
      @pager.per_page = 10
    end

    shared_examples_for "paginated sort strategy" do
      # @scope, @expected_sort, @strategy, and @reverse_strategy expected to be
      # set up in a before block

      it 'should order the students as expected' do
        expect(@strategy.paginate(@scope, @pager)).to eq @expected_sort
      end

      it 'should respect pagination' do
        @pager.per_page = 1
        @users.size.times do |i|
          @pager.current_page = i + 1
          expect(@strategy.paginate(@scope, @pager)).to eq @expected_sort[i, 1]
        end
      end

      it 'should handle accidental pagination past the end' do
        @pager.current_page = @users.size + 1
        @pager.per_page = 1
        expect{ @strategy.paginate(@scope, @pager) }.to raise_error Folio::InvalidPage
      end

      it 'should return a WillPaginate-style object' do
        expect(@strategy.paginate(@scope, @pager)).to respond_to(:current_page)
      end

      it 'should implement direction' do
        expect(@reverse_strategy.paginate(@scope, @pager)).to eq @expected_sort.reverse
      end
    end

    describe Analytics::StudentCollection::SortStrategy::ByName do
      before :each do
        assigned_names = ['Student 2', 'Student 1', 'Student 3']
        assigned_names.zip(@users).each { |name, user| user.update_attribute(:sortable_name, name) }
        @scope = User.active
        @strategy = Analytics::StudentCollection::SortStrategy::ByName.new
        @reverse_strategy = Analytics::StudentCollection::SortStrategy::ByName.new(:descending)
        @expected_sort = [1, 0, 2].map{ |i| @users[i] }
      end

      include_examples "paginated sort strategy"
    end

    describe Analytics::StudentCollection::SortStrategy::ByScore do
      let(:enrollment_count) { 4 }
      before :each do
        assigned_scores = [40, 20, nil, 60]
        assigned_scores.zip(@enrollments).each do |score, enrollment|
          enrollment.scores.where(grading_period_id: nil).first_or_initialize.tap do |s|
            s.current_score = score
            s.save!
          end
        end

        @scope = User.active.joins(:enrollments).
          joins("LEFT JOIN #{Score.quoted_table_name} scores ON
                scores.enrollment_id = enrollments.id AND
                scores.grading_period_id IS NULL AND
                scores.workflow_state <> 'deleted'")
        @strategy = Analytics::StudentCollection::SortStrategy::ByScore.new
        @reverse_strategy = Analytics::StudentCollection::SortStrategy::ByScore.new(:descending)
        @expected_sort = [2, 1, 0, 3].map{ |i| @users[i] }
      end

      include_examples "paginated sort strategy"
    end

    describe Analytics::StudentCollection::SortStrategy::ByPageViews do
      before :each do
        page_view_counts = {
          @users[0].id => { :page_views => 40, :participations => 10 },
          @users[1].id => { :page_views => 20, :participations => 10 },
          @users[2].id => { :page_views => 60, :participations => 10 },
        }
        @scope = User.active
        @strategy = Analytics::StudentCollection::SortStrategy::ByPageViews.new(page_view_counts)
        @reverse_strategy = Analytics::StudentCollection::SortStrategy::ByPageViews.new(page_view_counts, :descending)
        @expected_sort = [1, 0, 2].map{ |i| @users[i] }
      end

      include_examples "paginated sort strategy"
    end

    describe Analytics::StudentCollection::SortStrategy::ByParticipations do
      before :each do
        page_view_counts = {
          @users[0].id => { :participations => 40, :page_views => 100 },
          @users[1].id => { :participations => 20, :page_views => 100 },
          @users[2].id => { :participations => 60, :page_views => 100 },
        }
        @scope = User.active
        @strategy = Analytics::StudentCollection::SortStrategy::ByParticipations.new(page_view_counts)
        @reverse_strategy = Analytics::StudentCollection::SortStrategy::ByParticipations.new(page_view_counts, :descending)
        @expected_sort = [1, 0, 2].map{ |i| @users[i] }
      end

      include_examples "paginated sort strategy"
    end

    describe '.for(strategy_name)' do
      it "should recognize :name" do
        strategy = Analytics::StudentCollection::SortStrategy.for(:name)
        expect(strategy).to be_a(Analytics::StudentCollection::SortStrategy::ByName)
      end

      it "should recognize :name_ascending" do
        strategy = Analytics::StudentCollection::SortStrategy.for(:name_ascending)
        expect(strategy).to be_a(Analytics::StudentCollection::SortStrategy::ByName)
        expect(strategy.direction).to eq :ascending
      end

      it "should recognize :name_descending" do
        strategy = Analytics::StudentCollection::SortStrategy.for(:name_descending)
        expect(strategy).to be_a(Analytics::StudentCollection::SortStrategy::ByName)
        expect(strategy.direction).to eq :descending
      end

      it "should recognize :score" do
        strategy = Analytics::StudentCollection::SortStrategy.for(:score)
        expect(strategy).to be_a(Analytics::StudentCollection::SortStrategy::ByScore)
      end

      it "should recognize :score_ascending" do
        strategy = Analytics::StudentCollection::SortStrategy.for(:score_ascending)
        expect(strategy).to be_a(Analytics::StudentCollection::SortStrategy::ByScore)
        expect(strategy.direction).to eq :ascending
      end

      it "should recognize :score_descending" do
        strategy = Analytics::StudentCollection::SortStrategy.for(:score_descending)
        expect(strategy).to be_a(Analytics::StudentCollection::SortStrategy::ByScore)
        expect(strategy.direction).to eq :descending
      end

      it "should recognize :page_views" do
        strategy = Analytics::StudentCollection::SortStrategy.for(:page_views, :page_view_counts => {})
        expect(strategy).to be_a(Analytics::StudentCollection::SortStrategy::ByPageViews)
      end

      it "should recognize :page_views_ascending" do
        strategy = Analytics::StudentCollection::SortStrategy.for(:page_views_ascending, :page_view_counts => {})
        expect(strategy).to be_a(Analytics::StudentCollection::SortStrategy::ByPageViews)
        expect(strategy.direction).to eq :ascending
      end

      it "should recognize :page_views_descending" do
        strategy = Analytics::StudentCollection::SortStrategy.for(:page_views_descending, :page_view_counts => {})
        expect(strategy).to be_a(Analytics::StudentCollection::SortStrategy::ByPageViews)
        expect(strategy.direction).to eq :descending
      end

      it "should recognize :participations" do
        strategy = Analytics::StudentCollection::SortStrategy.for(:participations, :page_view_counts => {})
        expect(strategy).to be_a(Analytics::StudentCollection::SortStrategy::ByParticipations)
      end

      it "should recognize :participations_ascending" do
        strategy = Analytics::StudentCollection::SortStrategy.for(:participations_ascending, :page_view_counts => {})
        expect(strategy).to be_a(Analytics::StudentCollection::SortStrategy::ByParticipations)
        expect(strategy.direction).to eq :ascending
      end

      it "should recognize :participations_descending" do
        strategy = Analytics::StudentCollection::SortStrategy.for(:participations_descending, :page_view_counts => {})
        expect(strategy).to be_a(Analytics::StudentCollection::SortStrategy::ByParticipations)
        expect(strategy.direction).to eq :descending
      end

      it "should recognize nil as ByName" do
        strategy = Analytics::StudentCollection::SortStrategy.for(nil)
        expect(strategy).to be_a(Analytics::StudentCollection::SortStrategy::ByName)
      end

      it "should recognize unknown values as ByName" do
        strategy = Analytics::StudentCollection::SortStrategy.for(:bogus)
        expect(strategy).to be_a(Analytics::StudentCollection::SortStrategy::ByName)
      end

      it "should recognize strings" do
        strategy = Analytics::StudentCollection::SortStrategy.for("score")
        expect(strategy).to be_a(Analytics::StudentCollection::SortStrategy::ByScore)
      end

      it "should pass :page_view_counts to ByPageViews" do
        id = 5
        page_view_counts = { id => { :page_views => 0, :participations => 0 } }
        strategy = Analytics::StudentCollection::SortStrategy.for(:page_views, :page_view_counts => page_view_counts)
        expect(strategy.sorted_ids).to eq [id]
      end

      it "should pass :page_view_counts to ByParticipations" do
        id = 5
        page_view_counts = { id => { :page_views => 0, :participations => 0 } }
        strategy = Analytics::StudentCollection::SortStrategy.for(:participations, :page_view_counts => page_view_counts)
        expect(strategy.sorted_ids).to eq [id]
      end
    end
  end
end
