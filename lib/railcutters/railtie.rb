require "rails/railtie"
require "action_controller/metal/strong_parameters"

module Railcutters
  class Railtie < ::Rails::Railtie
    initializer "railcutters.load_action_controller" do
      next unless config.railcutters.use_params_renamer

      ::ActionController::Parameters.include(ActionController::ParamsRenamer)
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

      ::ActiveRecord::Base.extend(ActiveRecord::Pagination)
      ::ActionController::Metal.include(ActionController::Pagination)
    end

    initializer "railcutters.load_logging" do
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

    # This will force Rails internal logging to use a HashTaggedLogger instead of the default string
    # interface. This will not have any effect if you use Rails' standard Logger. In order to enable
    # it, you need to set your Rails logger to a HashTaggedLogger, for instance:
    #
    # config.logger = Railcutters::Logging::HashTaggedLogger.new(
    #   $stdout,
    #   formatter: Railcutters::Logging::HumanFriendlyFormatter.new
    # )
    config.railcutters.use_hashed_tagged_logging = true

    # This is a helper method to set all the defaults to a safe value, meaning that it will not make
    # any changes to the default behavior of Rails. This is useful if you are installing this gem
    # in an existing project and don't want to change any default behavior.
    config.railcutters.define_singleton_method(:set_safe_defaults!) do
      railcutters.active_record_enum_defaults = nil
      railcutters.active_record_enum_use_string_values = false
      railcutters.normalize_payload_keys = false
    end
  end
end
