require "active_support/concern"

# This module ensures that all logs related to action view are logged at debug level
module Railcutters::Logging::RailsExt::LogSubscriber::ActionView
  extend ActiveSupport::Concern

  prepended do
    alias_method :info, :debug
    subscribe_log_level :render_layout, :debug
    subscribe_log_level :render_template, :debug
  end
end
