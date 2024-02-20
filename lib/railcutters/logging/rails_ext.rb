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
        return unless Rails.configuration.logger.is_a?(Railcutters::Logging::KVTaggedLogger)

        load_patches
        load_subscribers
      end

      def self.load_patches
        require "rails/rack/logger"
        Rails::Rack::Logger.prepend(RackLogger)

        require "action_dispatch/middleware/debug_exceptions"
        ActionDispatch::DebugExceptions.prepend(ActionDispatchDebugExceptions)

        require_relative "rails_ext/active_job_logging"
      end

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
