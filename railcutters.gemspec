require_relative "lib/railcutters/version"

Gem::Specification.new do |s|
  s.name = "railcutters"
  s.version = Railcutters::VERSION
  s.summary = "An opinionated bundle for Rails web applications"
  s.license = "Apache 2.0"

  s.author = "Daniel Pereira"
  s.email = "daniel@garajau.com.br"
  s.homepage = "https://garajau.com.br"

  s.add_development_dependency "rspec", "~> 3.0"
  s.add_development_dependency "rails", ">= 7.1"
  s.add_development_dependency "debug", ">= 1.8"
  s.add_development_dependency "sqlite3", ">= 2.0"

  s.add_runtime_dependency "rails", ">= 7.1"
end
