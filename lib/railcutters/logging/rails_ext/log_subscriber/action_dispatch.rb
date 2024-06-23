require "active_support/log_subscriber"

module Railcutters::Logging::RailsExt::LogSubscriber
  class ActionDispatch < ActiveSupport::LogSubscriber
    # This gets triggered when a redirect is performed before reaching the controller
    def redirect(event)
      payload = event.payload
      status = payload[:status]

      info msg: "Request finished",
        status:,
        status_text: Rack::Utils::HTTP_STATUS_CODES[status],
        duration: "#{event.duration.round}ms"
    end
    subscribe_log_level :redirect, :info
  end
end
