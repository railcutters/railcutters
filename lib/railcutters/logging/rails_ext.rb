module Railcutters
  module Logging
    module RailsExt
      autoload :RackLogger, "railcutters/logging/rails_ext/rack_logger"
      autoload :ActionDispatchDebugExceptions, "railcutters/logging/rails_ext/action_dispatch_debug_exceptions"

      module LogSubscriber
        autoload :ActionController, "railcutters/logging/rails_ext/log_subscriber/action_controller"
        autoload :ActionDispatch, "railcutters/logging/rails_ext/log_subscriber/action_dispatch"
        autoload :ActionView, "railcutters/logging/rails_ext/log_subscriber/action_view"
        autoload :ActiveJob, "railcutters/logging/rails_ext/log_subscriber/active_job"
        autoload :ActiveStorage, "railcutters/logging/rails_ext/log_subscriber/active_storage"
      end

      def self.setup
        return unless ::Rails.configuration.logger.is_a?(Railcutters::Logging::KVTaggedLogger)

        load_patches
        load_subscribers
      end

      # It processes tags set in `config.log_tags` or `config.active_job.log_tags`, or any other
      # rails process executor that needs to support default tags.
      #
      # Supports the following ways of declaring the tags (both as a Hash and as an Array):
      #
      # config.log_tags = [:request_id]
      # config.log_tags = [Proc.new { |request| request.request_id }]
      # config.log_tags = {request_id: Proc.new { |request| request.request_id }}
      # config.log_tags = {tid: :request_id, user_id: Proc.new { |request| request.headers["User-ID"]}
      def self.process_default_tags(wrapper_object, tags)
        hash_tags = {}
        array_tags = []

        tags.each do |(key, value)|
          # Taggers can be either a hash or an Array. If it's a hash, then the variables `key` and
          # `value` will contain the key and value respectively. If it's an Array, then the variable
          # `key` will actually contain the value, while the variable `value` will be nil. In this
          # case, we want to use the value as the key and set key to nil.
          key, value = nil, key if value.nil?

          key, value = case value
            # For all other cases, we just use the key as is, and we support Proc out of the box
          when Proc
            [key, tag.call(wrapper_object)]
          when Symbol
            [key, wrapper_object.send(value)]
          else
            [key, value]
          end

          if key.nil?
            array_tags.push(value)
          else
            hash_tags[key] = value
          end
        end

        [hash_tags, array_tags]
      end

      # Injects and monkey patch Rails logging that is not covered by the log subscribers
      def self.load_patches
        require "rails/rack/logger"
        ::Rails::Rack::Logger.prepend(RackLogger)

        require "action_dispatch/middleware/debug_exceptions"
        ::ActionDispatch::DebugExceptions.prepend(ActionDispatchDebugExceptions)

        require_relative "rails_ext/active_job_logging"
      end

      # Replace all Rails log subscribers with our own
      def self.load_subscribers
        ::ActiveSupport.on_load(:action_controller, run_once: true) do
          require "action_controller/log_subscriber"
          ::ActionController::LogSubscriber.detach_from(:action_controller)
          LogSubscriber::ActionController.attach_to(:action_controller)
        end

        ::ActiveSupport.on_load(:action_dispatch_request, run_once: true) do
          require "action_dispatch/log_subscriber"
          ::ActionDispatch::LogSubscriber.detach_from(:action_dispatch)
          LogSubscriber::ActionDispatch.attach_to(:action_dispatch)
        end

        ::ActiveSupport.on_load(:action_view, run_once: true) do
          require "action_view/log_subscriber"
          ::ActionView::LogSubscriber.prepend(LogSubscriber::ActionView)
        end

        ::ActiveSupport.on_load(:active_storage_record, run_once: true) do
          require "active_storage/log_subscriber"
          ::ActiveStorage::LogSubscriber.detach_from(:active_storage)
          LogSubscriber::ActiveStorage.attach_to(:active_storage)
        end

        ::ActiveSupport.on_load(:active_job, run_once: true) do
          require "active_job/log_subscriber"
          ::ActiveJob::LogSubscriber.detach_from(:active_job)
          LogSubscriber::ActiveJob.attach_to(:active_job)
        end
      end
    end
  end
end
