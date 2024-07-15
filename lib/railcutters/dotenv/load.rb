require "railcutters/dotenv"

# Loads the env file(s) into the environment variables. It will look for the following files, in
# order:
#   - .env.<rails_env>.local
#   - .env.local
#   - .env.<rails_env>
#   - .env
#
# To use it, you must explicitly require this file in your `config/application.rb`:
# require "railcutters/dotenv/load"

if Bundler.locked_gems.specs.any? { |gem| gem.name == "dotenv" }
  raise "You have the gem 'dotenv' installed, which is not compatible with Railcutters."
end

Railcutters::Dotenv.load(
  ".env.#{::Rails.env}.local",
  ".env.local",
  ".env.#{::Rails.env}",
  ".env"
)
