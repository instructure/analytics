#
# Copyright (C) 2014 Instructure, Inc.
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
