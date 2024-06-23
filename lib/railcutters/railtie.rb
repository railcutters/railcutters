require "rails/railtie"
require "action_controller/metal/strong_parameters"
require "rails/generators/generated_attribute"
require "active_record/connection_adapters/abstract/schema_definitions"

module Railcutters
  class Railtie < ::Rails::Railtie
    initializer "railcutters.load_action_controller" do
      next unless config.railcutters.use_params_renamer

      ::ActionController::Parameters.include(ActionController::ParamsRenamer)
    end

    initializer "railcutters.load_sqlite_configs" do
      if config.railcutters.use_sqlite_tuning
        ::ActiveSupport.on_load(:active_record_sqlite3adapter) do
          # self refers to `SQLite3Adapter` here, so we can call .prepend directly
          prepend(ActiveRecord::ConnectionAdapters::SQLite3Tuning)
        end
      end

      if config.railcutters.use_sqlite_strictness
        # Configures SQLite with a strict strings mode, which disables double-quoted string literals.
        config.sqlite3_adapter_strict_strings_by_default = true

        ::ActiveSupport.on_load(:active_record_sqlite3adapter) do
          # self refers to `SQLite3Adapter` here, so we can call .prepend directly
          prepend(ActiveRecord::ConnectionAdapters::SQLite3Strictness)
        end
      end

      # Rails 8.0+ doesn't have this flag anymore
      if Gem::Version.new(Rails.version) < Gem::Version.new("7.2")
        # Allow us to use sqlite3 in production without warnings
        config.active_record.sqlite3_production_warning = false
      end
    end

    initializer "railcutters.load_migration_addons" do
      next unless config.railcutters.active_record_migration_defaults

      ::ActiveRecord::ConnectionAdapters::TableDefinition.prepend(
        ActiveRecord::ConnectionAdapters::DefaultTimestamps
      )
      ::Rails::Generators::GeneratedAttribute.prepend(Rails::Generators::VisualizeNulls)
    end

    initializer "railcutters.load_active_record" do
      next if config.railcutters.active_record_enum_defaults.blank?

      ::ActiveRecord::Base.extend(ActiveRecord::EnumDefaults)
    end

    initializer "railcutters.load_normalize_payload_keys" do
      next unless config.railcutters.normalize_payload_keys

      if defined?(Jbuilder)
        ::Jbuilder.key_format(camelize: :lower)
        ::Jbuilder.deep_format_keys(true)
      end

      ::ActiveSupport.on_load(:action_controller) do
        include(ActionController::FormatRequestParams)
      end
    end

    initializer "railcutters.load_pagination" do
      next unless config.railcutters.use_pagination

      ::ActiveRecord::Base.include(ActiveRecord::Pagination)
      ::ActionController::Metal.include(ActionController::Pagination)
    end

    initializer "railcutters.load_safe_sort" do
      next unless config.railcutters.use_safe_sort

      ::ActiveRecord::Base.include(ActiveRecord::SafeSort)
    end

    initializer "railcutters.load_logging", after: :initialize_logger do
      next unless config.railcutters.use_hashed_tagged_logging

      Logging::RailsExt.setup
    end

    # Settings to allow us to turn individual features on and off
    # ===========================================================

    config.railcutters = ::ActiveSupport::OrderedOptions.new

    # Enable loading the params renamer, and allows parameters renaming from within controllers
    # using an easy syntax
    config.railcutters.use_params_renamer = true

    # Enable a simple pagination helper for controllers and models, that exposes a `paginate` method
    # to the controller and the model, and sets the pagination metadata on the response using the
    # Pagination header.
    config.railcutters.use_pagination = true

    # Enable a new method (safe_sort) on models so that you can expose it safely to users and it's
    # guaranteed to be validated against a list of allowed columns.
    config.railcutters.use_safe_sort = true

    # Use SQLite3 strict mode
    # WARNING: this will affect new tables created with `rails db:migrate`, and you will not be able
    # to disable it once you enable it.
    config.railcutters.use_sqlite_strictness = true

    # Use sensible SQLite3 defaults to get more performance out of the box
    config.railcutters.use_sqlite_tuning = true

    # Use better defaults when creating and running migrations.
    # It will set the default value of every created_at/updated_at to the CURRENT_TIMESTAMP function
    # in the database, ensuring that it is created with the right values even outside rails.
    # It will also set `null: false` on the migrations. It is already the default behavior, but this
    # will make it explicit on the table definition.
    config.railcutters.active_record_migration_defaults = true

    # Use better defaults for ActiveRecord::Enum. Pass nil or an empty hash to use Rails' defaults.
    #
    # WARNING: this will affect existing code that uses `enum`, so you should only enable this if
    # you're starting a new project or are willing to change your existing code.
    config.railcutters.active_record_enum_defaults = {
      # Keeping a prefix for all methods generated by a enum is a good idea to avoid conflicts
      prefix: true,

      # New in Rails 7.1: Instead of raising an error when an invalid value is passed to an enum, it
      # validates the value and adds an error to the record instead
      validate: {allow_nil: true},

      # Both these options below are the Rails' defaults, but we're setting them explicitly here for
      # clarity's sake
      instance_methods: true,
      scopes: true
    }

    # This will convert any array passed as the second argument to ActiveRecord::Enum to a hash,
    # being the same value for both the key and the value. This is useful when you want to use
    # string values for your enums, but don't want to repeat yourself.
    # The official Rails' documentations says that this will likely lead to slower database queries,
    # but it's a tradeoff worth making in most cases for a better developer experience.
    #
    # WARNING: this will affect existing code that uses `enum`, so you should only enable this if
    # you're starting a new project or are willing to change your existing code.
    config.railcutters.active_record_enum_use_string_values = true

    # This will normalize the keys of the payload sent to and from the controller to be snake_case
    # instead of camelCase.
    #
    # This is useful if you are using a frontend framework that uses camelCase, but you want to keep
    # your backend code in snake_case. To normalize parameters sent from the controller, you need to
    # use JBuilder.
    #
    # WARNING: this will affect existing code that rely on using camelCase keys, so you should only
    # enable this if you're starting a new project or are willing to change your existing code.
    config.railcutters.normalize_payload_keys = true

    # This will force Rails internal logging to use a KVTaggedLogger instead of the default string
    # interface. This will not have any effect if you use Rails' standard Logger. In order to enable
    # it, you need to set your Rails logger to a KVTaggedLogger, for instance:
    #
    # config.logger = Railcutters::Logging::KVTaggedLogger.new(
    #   $stdout,
    #   formatter: Railcutters::Logging::HumanFriendlyFormatter.new
    # )
    config.railcutters.use_hashed_tagged_logging = true

    # This is a helper method to set all the defaults to a safe value, meaning that it will not make
    # any changes to the default behavior of Rails. This is useful if you are installing this gem
    # in an existing project and don't want to change any default behavior.
    config.railcutters.define_singleton_method(:use_safe_defaults!) do
      railcutters.active_record_enum_defaults = nil
      railcutters.active_record_enum_use_string_values = false
      railcutters.normalize_payload_keys = false
    end
  end
end
