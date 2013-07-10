module Analytics
  class Base
    def initialize(current_user)
      @current_user = current_user
    end

    def self.cache_expiry
      Setting.get('analytics_cache_expiry', 12.hours.to_s).to_i
    end

  private

    include Slave

    def cache(key)
      Rails.cache.fetch(['analytics', cache_prefix, key].cache_key, :expires_in => Analytics::Base.cache_expiry) { yield }
    end

    def slaved(opts={})
      if opts[:cache_as]
        cache(opts[:cache_as]) { super() }
      else
        super()
      end
    end
  end
end
