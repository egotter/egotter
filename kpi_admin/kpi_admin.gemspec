$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "kpi_admin/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "kpi_admin"
  s.version     = KpiAdmin::VERSION
  s.authors     = ["Shinohara Teruki"]
  s.email       = ["ts_3156@yahoo.co.jp"]
  s.homepage    = "http://example.com"
  s.summary     = "Summary of KpiAdmin."
  s.description = "Description of KpiAdmin."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 4.2.5"
  s.add_dependency "activesupport"
  s.add_dependency "jquery-rails"
  s.add_dependency "haml-rails"

  s.add_development_dependency "mysql2"
end
