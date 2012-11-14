module Analytics
  module Slave
    def self.slaved
      ActiveRecord::Base::ConnectionSpecification.with_environment(:slave) { yield }
    end

    def slaved
      Analytics::Slave.slaved{ yield }
    end
  end
end
