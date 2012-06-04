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

    def slaved(opts={})
      if opts[:cache_as]
        Rails.cache.fetch(['analytics', cache_prefix, opts[:cache_as]].cache_key, :expires_in => 12.hours) do
          self.class.slaved{ yield }
        end
      else
        self.class.slaved{ yield }
      end
    end
  end
end
