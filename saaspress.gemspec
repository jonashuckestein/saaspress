$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "saaspress/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "saaspress"
  s.version     = Saaspress::VERSION
  s.authors     = ["Jonas Huckestein"]
  s.email       = ["jonas.huckestein@gmail.com"]
  s.homepage    = "https://hipdial.com"
  s.summary     = "Shared code of HipDial and ContactSales."
  s.description = "Blub"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 4.1.0"
  s.add_dependency "useragent"

  s.add_dependency "mixpanel-ruby"
  s.add_dependency "keen"
  s.add_dependency "intercom"
  s.add_dependency "turbolinks"
  s.add_dependency "local_time"
  s.add_dependency 'bootstrap-sass', '~> 3.2.0'
  s.add_dependency 'sass-rails', '>= 3.2'
  s.add_dependency "coffee-rails", ">= 4.0.0"
  s.add_dependency "jquery-rails"
  s.add_dependency "haml-rails"

  s.add_development_dependency "sqlite3"
end
