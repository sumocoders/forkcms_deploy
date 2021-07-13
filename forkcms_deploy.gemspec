# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "forkcms_deploy"
  s.version = "4.4.6"

  s.authors = ["Tijs Verkoyen", "Jan De Poorter", "Sam Tubbax", "Wouter Sioen"]
  s.date = "2021-06-15"
  s.description = "Deployment for ForkCMS with Capistrano"
  s.summary = "Deployment for ForkCMS with Capistrano ..."
  s.email = "info@sumocoders.be"
  s.files = [
    "README.md",
    "forkcms_deploy.gemspec",
    "lib/forkcms_deploy.rb",
    "lib/forkcms_deploy/defaults.rb",
    "lib/forkcms_deploy/forkcms.rb",
    "lib/forkcms_deploy/forkcms_2.rb",
    "lib/forkcms_deploy/forkcms_3.4.rb",
    "lib/forkcms_deploy/forkcms_3.5.rb",
    "lib/forkcms_deploy/forkcms_3.7.rb",
    "lib/forkcms_deploy/forkcms_3.8.rb",
    "lib/forkcms_deploy/forkcms_3.rb",
    "lib/forkcms_deploy/forkcms_4.rb",
    "lib/forkcms_deploy/forkcms_default.rb",
    "lib/forkcms_deploy/overwrites.rb",
    "lib/maintenance/.htaccess",
    "lib/maintenance/index.html",
    "test/test_forkcms_deploy.rb"
  ]
  s.homepage = "https://github.com/sumocoders/forkcms_deploy"
  s.require_paths = ["lib"]
  s.licenses = ["MIT"]

  s.add_dependency "capistrano", "~> 2.15"
end

