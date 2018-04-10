$:.push File.expand_path("../lib", __FILE__)

require 'analytics/version'

Gem::Specification.new do |spec|
  spec.name          = "analytics"
  spec.version       = Analytics::VERSION
  spec.authors       = ["Jacob Fugal"]
  spec.email         = ["jacob@instructure.com"]
  spec.homepage      = "http://www.instructure.com"
  spec.summary       = %q{Analytics engine for the canvas-lms platform}
  spec.license       = "AGPL-3.0"

  spec.files = Dir["{app,config,db,lib,public}/**/*"]
  spec.test_files = Dir["spec_canvas/**/*"]

  spec.add_dependency "rails", ">= 3.2"
  spec.add_dependency "autoextend", "~>1.0.0"
end
