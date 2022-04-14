# frozen_string_literal: true

# we don't want zeitwerk to try to eager_load some
# "Version" constant from analytics/version.
Rails.autoloaders.main.ignore("#{__dir__}/../../lib/analytics/version.rb")
