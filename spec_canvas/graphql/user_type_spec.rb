require_relative '../../../../../spec/spec_helper'
require_relative '../../../../../spec/helpers/graphql_type_tester'

describe Types::UserType do
  let_once(:user) { student_in_course(active_all: true).user }
  let(:student_type) { GraphQLTypeTester.new(Types::UserType, user) }

  before {
    Account.default.enable_service(:analytics)
    Account.default.save!
  }

  context "summaryAnalytics" do
    it "works" do
      expect(
        student_type.summaryAnalytics(
          args: {courseId: @course.id.to_s},
          current_user: @teacher
        )
      ).to be_a Analytics::StudentSummary
    end

    it "is nil when analytics is not enabled" do
      Account.default.disable_service(:analytics)
      Account.default.save!
      expect(
        student_type.summaryAnalytics(
          args: {courseId: @course.id.to_s},
          current_user: @teacher
        )
      ).to be_nil
    end

    it "is nil for teachers without permission" do
      RoleOverride.manage_role_override(
        Account.default, teacher_role, 'view_analytics',
        override: false
      )
      expect(
        student_type.summaryAnalytics(
          args: {courseId: @course.id.to_s},
          current_user: @teacher
        )
      ).to be_nil
    end

    it "is nil for students" do
      expect(
        student_type.summaryAnalytics(
          args: {courseId: @course.id.to_s},
          current_user: @student
        )
      ).to be_nil
    end
  end
end
