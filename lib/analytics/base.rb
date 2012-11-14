module Analytics
  class Base
    def initialize(current_user, session)
      @current_user = current_user
      @session = session
    end

  private

    include Slave

    def cache(key)
      Rails.cache.fetch(['analytics', cache_prefix, key].cache_key, :expires_in => 12.hours) { yield }
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
