#
# Copyright (C) 2018 Instructure, Inc.
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

require_relative '../../../../../spec/spec_helper.rb'

describe Loaders::CourseStudentAnalyticsLoader do
  before do
    @account = Account.default
    @account.allowed_services = '+analytics'
    @account.save!
  end

  it "should work" do
    course_with_student(active_all: true)
    GraphQL::Batch.batch do
      Loaders::CourseStudentAnalyticsLoader.
        for(@course.id, current_user: @teacher, session: nil).
        load(@student).then { |result|
          expect(result).to be_a(Analytics::StudentSummary)
        }
    end
  end

  it "returns nil for completed or inactive courses" do
    course_with_student
    GraphQL::Batch.batch do
      Loaders::CourseStudentAnalyticsLoader.
        for(@course.id, current_user: @teacher, session: nil).
        load(@student).then { |result|
          expect(result).to be_nil
        }
    end
  end
end
