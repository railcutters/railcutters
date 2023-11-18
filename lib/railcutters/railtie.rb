require "rails/railtie"
require "action_controller/metal/strong_parameters"

module Railcutters
  class Railtie < ::Rails::Railtie
    initializer "railcutters.load_action_controller" do
      return unless config.railcutters.use_params_renamer

      ::ActionController::Parameters.include(ActionController::ParamsRenamer)
    end

    initializer "railcutters.load_sqlite_sensible_defaults" do
      next unless config.railcutters.use_sqlite_better_defaults

      ActiveSupport.on_load(:active_record_sqlite3adapter) do
        # self refers to `SQLite3Adapter` here, so we can call .include directly
        include(ActiveRecord::ConnectionAdapters::SQLite3Adapter)
      end

      # Configures SQLite with a strict strings mode, which disables double-quoted string literals.
      config.sqlite3_adapter_strict_strings_by_default = true
      # Allow us to use sqlite3 in production without warnings
      config.active_record.sqlite3_production_warning = false
    end

    # Settings to allow us to turn individual features on and off
    # ===========================================================

    config.railcutters = ActiveSupport::OrderedOptions.new

    # Enable loading the params renamer, and allows parameters renaming from within controllers
    # using an easy syntax
    config.railcutters.use_params_renamer = true

    # Use sensible SQLite3 defaults such as enabling WAL and strict mode.
    config.railcutters.use_sqlite_better_defaults = true
  end
end
