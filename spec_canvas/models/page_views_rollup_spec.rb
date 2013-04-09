require File.expand_path(File.dirname(__FILE__) + '/../../../../../spec/sharding_spec_helper')

describe PageViewsRollup do
  def create_rollup(opts={})
    rollup = PageViewsRollup.new
    rollup.course = opts[:course]
    rollup.date = opts[:date]
    rollup.category = opts[:category]
    rollup.save unless opts[:no_save]
    rollup
  end

  describe ".for_dates" do
    before :each do
      @course = course_model
    end

    it "should work for a single date" do
      today = Date.today
      rollup = create_rollup(:course => @course, :date => today, :category => 'other')
      other = create_rollup(:course => @course, :date => today - 1.day, :category => 'other')
      PageViewsRollup.for_dates(today).should include(rollup)
      PageViewsRollup.for_dates(today).should_not include(other)
    end

    it "should work for a date range" do
      end_day = Date.today - 1.day
      start_day = end_day - 3.days

      rollups = (start_day..end_day).map do |day|
        create_rollup(:course => @course, :date => day, :category => 'other')
      end
      before_start = create_rollup(:course => @course, :date => start_day - 1.day, :category => 'other')
      after_end = create_rollup(:course => @course, :date => end_day + 1.day, :category => 'other')

      rollups.each do |rollup|
        PageViewsRollup.for_dates(start_day..end_day).should include(rollup)
      end
      PageViewsRollup.for_dates(start_day..end_day).should_not include(before_start)
      PageViewsRollup.for_dates(start_day..end_day).should_not include(after_end)
    end
  end

  describe ".for_category" do
    before :each do
      @course = course_model
      @today = Date.today
    end

    it "should include all rollups for that category" do
      rollup1 = create_rollup(:course => @course, :date => @today, :category => 'first')
      rollup2 = create_rollup(:course => course_model, :date => @today, :category => 'first')
      PageViewsRollup.for_category('first').should include(rollup1)
      PageViewsRollup.for_category('first').should include(rollup2)
    end

    it "should only include rollups for that category" do
      rollup1 = create_rollup(:course => @course, :date => @today, :category => 'first')
      rollup2 = create_rollup(:course => @course, :date => @today, :category => 'second')
      PageViewsRollup.for_category('first').should include(rollup1)
      PageViewsRollup.for_category('first').should_not include(rollup2)
    end
  end

  describe ".bin_for" do
    before :each do
      @course = course_model
      @today = Date.today
      @category = 'other'
    end

    context "new bin" do
      before :each do
        @bin = PageViewsRollup.bin_for(@course, @today, @category)
      end

      it "should be a new record" do
        @bin.should be_new_record
      end

      it "should initialize views to 0 on a new bin" do
        @bin.views.should == 0
      end

      it "should initialize participations to 0 on a new bin" do
        @bin.participations.should == 0
      end
    end

    context "existing bin" do
      before :each do
        @initial = PageViewsRollup.bin_for(@course, @today, @category)
        @initial.views = 5
        @initial.participations = 2
        @initial.save

        @existing = PageViewsRollup.bin_for(@course, @today, @category)
      end

      it "should not return new bin" do
        @existing.should == @initial
      end

      it "should not reset views" do
        @existing.views.should == @initial.views
      end

      it "should not reset participations" do
        @existing.participations.should == @initial.participations
      end
    end

    context "sharding" do
      specs_require_sharding

      context "new bin" do
        it "should return a bin on the correct shard given an AR object" do
          @shard1.activate do
            bin = PageViewsRollup.bin_for(@course, @today, @category)
            bin.shard.should == @course.shard
            bin.course_id.should == @course.id
          end
        end

        it "should return a bin on the correct shard given a non-local id" do
          @shard1.activate do
            bin = PageViewsRollup.bin_for(@course.id, @today, @category)
            bin.shard.should == @course.shard
            bin.course_id.should == @course.id
          end
        end
      end

      context "existing bin" do
        before do
          @existing = PageViewsRollup.bin_for(@course, @today, @category)
          @existing.save!
        end

        it "should return the correct bin given an AR object" do
          @shard1.activate do
            PageViewsRollup.bin_for(@course, @today, @category).should == @existing
          end
        end

        it "should return the correct bin given a non-local id" do
          @shard1.activate do
            PageViewsRollup.bin_for(@course.id, @today, @category).should == @existing
          end
        end
      end
    end
  end

  describe "#augment" do
    before :each do
      @bin = PageViewsRollup.bin_for(course_model, Date.today, 'other')
    end

    it "should increase views" do
      @bin.views.should == 0
      @bin.augment(5, 2)
      @bin.views.should == 5
      @bin.augment(5, 2)
      @bin.views.should == 10
    end

    it "should increase participations" do
      @bin.participations.should == 0
      @bin.augment(5, 2)
      @bin.participations.should == 2
      @bin.augment(5, 2)
      @bin.participations.should == 4
    end
  end

  describe ".augment!" do
    it "should augment the appropriate bin and save" do
      @course = course_model
      @today = Date.today
      @category = 'other'

      bin = mock('bin')
      PageViewsRollup.stubs(:bin_for).with(@course, @today, @category).returns(bin)
      bin.expects(:augment).with(5, 2).once
      bin.expects(:save).once

      PageViewsRollup.augment!(@course, @today, @category, 5, 2)
    end
  end

  describe ".increment_db!" do
    it "should augment the appropriate bin by 1" do
      @course = course_model
      @today = Date.today
      @category = 'other'

      PageViewsRollup.expects(:augment!).with(@course, @today, @category, 1, 1).once
      PageViewsRollup.increment_db!(@course, @today, @category, true)
    end

    it "should augment the bin's participations only if participated" do
      @course = course_model
      @today = Date.today
      @category = 'other'

      PageViewsRollup.expects(:augment!).with(@course, @today, @category, 1, 0).once
      PageViewsRollup.increment_db!(@course, @today, @category, false)
    end
  end

  if Canvas.redis_enabled?
    context "with redis" do
      before(:each) do
        Setting.set("page_view_rollups_method", "redis")
        Canvas.redis.flushdb
      end

      describe ".increment_cached!" do
        it "should increment via redis and a batch job" do
          @course = course_model
          @today = Date.today
          @category = 'other'

          PageViewsRollup.increment!(@course, @today, @category, false)
          PageViewsRollup.count.should == 0

          PageViewsRollup.process_cached_rollups
          PageViewsRollup.count.should == 1

          pvr = PageViewsRollup.last
          pvr.course_id.should == @course.id
          pvr.date.should == @today
          pvr.category.should == @category
          pvr.views.should == 1
          pvr.participations.should == 0

          # you should be able to supply Course or course_id
          PageViewsRollup.increment!(@course.id, @today, @category, true)
          PageViewsRollup.count.should == 1

          PageViewsRollup.process_cached_rollups
          PageViewsRollup.count.should == 1

          pvr = PageViewsRollup.last
          pvr.views.should == 2
          pvr.participations.should == 1
        end
      end
    end
  end
end
