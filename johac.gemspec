$:.push File.expand_path("../lib", __FILE__)

require "johac/version"

spec = Gem::Specification.new do |s|
  s.name = "johac"
  s.version = Johac::Version
  s.license = "MIT"
  s.date = "2018-05-29"
  s.summary = "JSON Over HTTP API Client"
  s.email = "dan.simpson@gmail.com"
  s.homepage = "https://github.com/dansimpson/johac"
  s.description = "Opintionated library for implement HTTP+JSON API clients"
  s.has_rdoc = true

  s.add_dependency("faraday", "~> 0.15.2", ">= 0.9.2")
  s.add_dependency('faraday_middleware', '~> 0.12.2')
  s.add_dependency("net-http-persistent", "~> 2.9", ">= 2.9.4")

  s.add_development_dependency("rake", "~> 10.4", ">= 10.4.2")
  s.add_development_dependency("rack", "~> 1.4")
  s.add_development_dependency("webmock", "~> 3.3.0")
  s.add_development_dependency("yard", '~> 0.8.7.6')
  s.add_development_dependency("minitest", '~> 4.7', '>= 4.7.5')

  s.authors = ["Dan Simpson"]

  s.files = Dir["lib/**/*.rb"]

end
