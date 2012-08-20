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

    def cache(key)
      Rails.cache.fetch(['analytics', cache_prefix, key].cache_key, :expires_in => 12.hours) do
        yield
      end
    end

    def slaved(opts={})
      if opts[:cache_as]
        cache(opts[:cache_as]) do
          self.class.slaved{ yield }
        end
      else
        self.class.slaved{ yield }
      end
    end
  end
end
