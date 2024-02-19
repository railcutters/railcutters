require "action_controller/log_subscriber"

module Railcutters::Logging::RailsExt::LogSubscriber
  class ActionController < ::ActionController::LogSubscriber
    def start_processing(event)
      debug do
        payload = event.payload

        params = {}
        payload[:params].each_pair do |k, v|
          params[k] = v unless INTERNAL_PARAMS.include?(k)
        end
        params = params.inspect if params.any?

        format = payload[:format]
        format = format.to_s.upcase if format.is_a?(Symbol)
        format = "*/*" if format.nil?

        {msg: "Processing request",
         action: "#{payload[:controller]}##{payload[:action]}",
         format:, params:}.compact_blank
      end
    end
    subscribe_log_level :start_processing, :debug

    def process_action(event)
      info do
        payload = event.payload
        status = payload[:status]

        if status.nil? && (exception_class_name = payload[:exception]&.first)
          status = ActionDispatch::ExceptionWrapper.status_code_for_exception(exception_class_name)
        end

        if payload[:view_runtime]
          views = "%.1fms" % payload[:view_runtime].to_f
        end

        if payload[:db_runtime]
          db = "%.1fms" % payload[:db_runtime].to_f
        end

        allocations = event.allocations

        {msg: "Request finished", status:, status_text: Rack::Utils::HTTP_STATUS_CODES[status],
         duration: "#{event.duration.round}ms", views:, db:, allocations:}.compact_blank
      end
    end
    subscribe_log_level :process_action, :info
  end
end
