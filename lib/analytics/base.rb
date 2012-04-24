module Analytics
  class Base
    def initialize(current_user, session)
      @current_user = current_user
      @session = session
    end

  private

    def self.slaved
      ActiveRecord::Base::ConnectionSpecification.with_environment(:slave) { yield }
    end

    def slaved
      self.class.slaved{ yield }
    end
  end
end
