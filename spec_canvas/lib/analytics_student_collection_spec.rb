require File.expand_path(File.dirname(__FILE__) + '/../../../../../spec/spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../cassandra_spec_helper')

describe Analytics::StudentCollection do
  it "should default sort_strategy to Default" do
    collection = Analytics::StudentCollection.new(User)
    collection.sort_strategy.should be_a(Analytics::StudentCollection::SortStrategy::Default)
  end

  describe "#sort_by" do
    it "should set the sort_strategy" do
      collection = Analytics::StudentCollection.new(User)
      collection.sort_by(:score)
      collection.sort_strategy.should be_a(Analytics::StudentCollection::SortStrategy::ByScore)
    end

    it "should pass along options" do
      id = 5
      page_view_counts = { id => { :page_views => 0, :participations => 0 } }
      collection = Analytics::StudentCollection.new(User)
      collection.sort_by(:page_views, :page_view_counts => page_view_counts)
      collection.sort_strategy.sorted_ids.should == [id]
    end
  end

  describe "#format" do
    it "should set the formatter" do
      formatter = proc{}
      collection = Analytics::StudentCollection.new(User)
      collection.format(&formatter)
      collection.formatter.should == formatter
    end
  end

  describe "#paginate" do
    before :each do
      User.update_all workflow_state: 'deleted'
      @course = Course.create! # no teacher, please
      @enrollments = Array.new(3) { student_in_course(:active_all => true) }
      @users = @enrollments.map(&:user)
    end

    it "should paginate values from the initial scope" do
      collection = Analytics::StudentCollection.new(User.active)
      students = collection.paginate(:page => 1, :per_page => 3)
      students.map(&:id).sort.should == @users.map(&:id).sort
    end

    it "should use the specified sort strategy" do
      collection = Analytics::StudentCollection.new(User.active)
      collection.sort_by(:page_views, :page_view_counts => {
        @users[0].id => { :page_views => 40, :participations => 10 },
        @users[1].id => { :page_views => 20, :participations => 10 },
        @users[2].id => { :page_views => 60, :participations => 10 },
      })
      students = collection.paginate(:page => 1, :per_page => 3)
      students.should == [1, 0, 2].map{ |i| @users[i] }
    end

    it "should pass the results through the formatter" do
      collection = Analytics::StudentCollection.new(User.active)
      collection.format { "formatted" }
      students = collection.paginate(:page => 1, :per_page => 3)
      students.should == Array.new(3) { "formatted" }
    end
  end

  describe 'sort strategies' do
    let(:enrollment_count) { 3 }
    before :each do
      User.update_all workflow_state: 'deleted'
      @course = Course.create! # no teacher, please
      @enrollments = Array.new(enrollment_count) { student_in_course(:active_all => true) }
      @users = @enrollments.map(&:user)
      @pager = PaginatedCollection::Collection.new
      @pager.current_page = 1
      @pager.per_page = 10
    end

    shared_examples_for "paginated sort strategy" do
      # @scope, @expected_sort, @strategy, and @reverse_strategy expected to be
      # set up in a before block

      it 'should order the students as expected' do
        @strategy.paginate(@scope, @pager).should == @expected_sort
      end

      it 'should respect pagination' do
        @pager.per_page = 1
        @users.size.times do |i|
          @pager.current_page = i + 1
          @strategy.paginate(@scope, @pager).should == @expected_sort[i, 1]
        end
      end

      it 'should handle accidental pagination past the end' do
        @pager.current_page = @users.size + 1
        @pager.per_page = 1
        @strategy.paginate(@scope, @pager).should == []
      end

      it 'should return a WillPaginate-style object' do
        @strategy.paginate(@scope, @pager).should respond_to(:current_page)
      end

      it 'should implement direction' do
        @reverse_strategy.paginate(@scope, @pager).should == @expected_sort.reverse
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

      it_should_behave_like "paginated sort strategy"
    end

    describe Analytics::StudentCollection::SortStrategy::ByScore do
      let(:enrollment_count) { 4 }
      before :each do
        assigned_scores = [40, 20, nil, 60]
        assigned_scores.zip(@enrollments).each { |score, enrollment| enrollment.update_attribute(:computed_current_score, score) }
        @scope = User.active.joins("INNER JOIN enrollments ON enrollments.user_id=users.id")
        @strategy = Analytics::StudentCollection::SortStrategy::ByScore.new
        @reverse_strategy = Analytics::StudentCollection::SortStrategy::ByScore.new(:descending)
        @expected_sort = [2, 1, 0, 3].map{ |i| @users[i] }
      end

      it_should_behave_like "paginated sort strategy"
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

      it_should_behave_like "paginated sort strategy"
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

      it_should_behave_like "paginated sort strategy"
    end

    describe '.for(strategy_name)' do
      it "should recognize :name" do
        strategy = Analytics::StudentCollection::SortStrategy.for(:name)
        strategy.should be_a(Analytics::StudentCollection::SortStrategy::ByName)
      end

      it "should recognize :name_ascending" do
        strategy = Analytics::StudentCollection::SortStrategy.for(:name_ascending)
        strategy.should be_a(Analytics::StudentCollection::SortStrategy::ByName)
        strategy.direction.should == :ascending
      end

      it "should recognize :name_descending" do
        strategy = Analytics::StudentCollection::SortStrategy.for(:name_descending)
        strategy.should be_a(Analytics::StudentCollection::SortStrategy::ByName)
        strategy.direction.should == :descending
      end

      it "should recognize :score" do
        strategy = Analytics::StudentCollection::SortStrategy.for(:score)
        strategy.should be_a(Analytics::StudentCollection::SortStrategy::ByScore)
      end

      it "should recognize :score_ascending" do
        strategy = Analytics::StudentCollection::SortStrategy.for(:score_ascending)
        strategy.should be_a(Analytics::StudentCollection::SortStrategy::ByScore)
        strategy.direction.should == :ascending
      end

      it "should recognize :score_descending" do
        strategy = Analytics::StudentCollection::SortStrategy.for(:score_descending)
        strategy.should be_a(Analytics::StudentCollection::SortStrategy::ByScore)
        strategy.direction.should == :descending
      end

      it "should recognize :page_views" do
        strategy = Analytics::StudentCollection::SortStrategy.for(:page_views, :page_view_counts => {})
        strategy.should be_a(Analytics::StudentCollection::SortStrategy::ByPageViews)
      end

      it "should recognize :page_views_ascending" do
        strategy = Analytics::StudentCollection::SortStrategy.for(:page_views_ascending, :page_view_counts => {})
        strategy.should be_a(Analytics::StudentCollection::SortStrategy::ByPageViews)
        strategy.direction.should == :ascending
      end

      it "should recognize :page_views_descending" do
        strategy = Analytics::StudentCollection::SortStrategy.for(:page_views_descending, :page_view_counts => {})
        strategy.should be_a(Analytics::StudentCollection::SortStrategy::ByPageViews)
        strategy.direction.should == :descending
      end

      it "should recognize :participations" do
        strategy = Analytics::StudentCollection::SortStrategy.for(:participations, :page_view_counts => {})
        strategy.should be_a(Analytics::StudentCollection::SortStrategy::ByParticipations)
      end

      it "should recognize :participations_ascending" do
        strategy = Analytics::StudentCollection::SortStrategy.for(:participations_ascending, :page_view_counts => {})
        strategy.should be_a(Analytics::StudentCollection::SortStrategy::ByParticipations)
        strategy.direction.should == :ascending
      end

      it "should recognize :participations_descending" do
        strategy = Analytics::StudentCollection::SortStrategy.for(:participations_descending, :page_view_counts => {})
        strategy.should be_a(Analytics::StudentCollection::SortStrategy::ByParticipations)
        strategy.direction.should == :descending
      end

      it "should recognize nil as ByName" do
        strategy = Analytics::StudentCollection::SortStrategy.for(nil)
        strategy.should be_a(Analytics::StudentCollection::SortStrategy::ByName)
      end

      it "should recognize unknown values as ByName" do
        strategy = Analytics::StudentCollection::SortStrategy.for(:bogus)
        strategy.should be_a(Analytics::StudentCollection::SortStrategy::ByName)
      end

      it "should recognize strings" do
        strategy = Analytics::StudentCollection::SortStrategy.for("score")
        strategy.should be_a(Analytics::StudentCollection::SortStrategy::ByScore)
      end

      it "should pass :page_view_counts to ByPageViews" do
        id = 5
        page_view_counts = { id => { :page_views => 0, :participations => 0 } }
        strategy = Analytics::StudentCollection::SortStrategy.for(:page_views, :page_view_counts => page_view_counts)
        strategy.sorted_ids.should == [id]
      end

      it "should pass :page_view_counts to ByParticipations" do
        id = 5
        page_view_counts = { id => { :page_views => 0, :participations => 0 } }
        strategy = Analytics::StudentCollection::SortStrategy.for(:participations, :page_view_counts => page_view_counts)
        strategy.sorted_ids.should == [id]
      end
    end
  end
end
