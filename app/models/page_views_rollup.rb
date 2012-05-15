# while the rows will only ever be queried with respect courses that are
# available or completed course, we don't know at the time of rollup what the
# future workflow state of course will be. so we have to keep rollup data for
# all courses.
class PageViewsRollup < ActiveRecord::Base
  attr_accessible

  belongs_to :course

  named_scope :for_course, lambda{ |course|
    course_id = course.instance_of?(Course) ? course.id : course
    { :conditions => { :course_id => course_id } }
  }

  named_scope :for_dates, lambda{ |date_range|
    { :conditions => { :date => date_range } }
  }

  named_scope :for_category, lambda{ |category|
    { :conditions => { :category => category } }
  }

  def augment(views, participations)
    self.views += views
    self.participations += participations
  end

  def self.bin_for(course, date, category)
    course_id = course.instance_of?(Course) ? course.id : course
    category = category.to_s

    bin = self.
      for_course(course_id).
      for_dates(date).
      for_category(category).
      first

    unless bin
      bin = self.new
      bin.course_id = course_id
      bin.date = date
      bin.category = category
      bin.views = 0
      bin.participations = 0
    end

    bin
  end

  def self.augment!(course, date, category, views, participations)
    bin = bin_for(course, date, category)
    bin.augment(views, participations)
    bin.save
  end

  def self.increment!(course, date, category, participated)
    augment!(course, date, category, 1, participated ? 1 : 0)
  end
end
