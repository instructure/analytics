# frozen_string_literal: true

require_relative "lib/analytics/version"

Gem::Specification.new do |spec|
  spec.name          = "analytics"
  spec.version       = Analytics::VERSION
  spec.authors       = ["Jacob Fugal"]
  spec.email         = ["jacob@instructure.com"]
  spec.homepage      = "http://www.instructure.com"
  spec.summary       = "Analytics engine for the canvas-lms platform"
  spec.license       = "AGPL-3.0"

  spec.files = Dir["{app,config,db,lib,public}/**/*"]

  spec.add_dependency "autoextend", "~>1.0.0"
  spec.add_dependency "rails", ">= 3.2"
end
