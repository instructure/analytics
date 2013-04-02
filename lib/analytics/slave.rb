module Analytics
  module Slave
    def self.slaved
      Shackles.activate(:slave) { yield }
    end

    def slaved
      Analytics::Slave.slaved{ yield }
    end
  end
end
