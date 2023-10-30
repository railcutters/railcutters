require File.expand_path("../lib/railcutters/version", __FILE__)

Gem::Specification.new do |s|
  s.name = "railcutters"
  s.version = Railcutters::VERSION
  s.summary = "An opinionated bundle for Rails web applications"
  s.license = "Apache 2.0"

  s.author = "Daniel Pereira"
  s.email = "daniel@garajau.com.br"
  s.homepage = "https://garajau.com.br"

  s.add_development_dependency "rspec", "~> 3.0"
  s.add_development_dependency "rails", ">= 7.0"

  s.add_runtime_dependency "rails", ">= 7.0"
end
