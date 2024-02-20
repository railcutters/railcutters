# This is an override module to ActionDispatch::DebugExceptions middleware so that exceptions
# captured by it correctly logs them using KVTaggedLogger
module Railcutters::Logging::RailsExt::ActionDispatchDebugExceptions
  def log_error(request, wrapper)
    logger = logger(request)

    return unless logger
    return if !log_rescued_responses?(request) && wrapper.rescue_response?

    level = request.get_header("action_dispatch.debug_exception_log_level")
    trace = wrapper.exception_trace

    logger.add(level,
      msg: "Exception raised",
      exception: wrapper.exception_class_name,
      error: wrapper.message,
      annotated_source_code: wrapper.annotated_source_code,
      trace: trace)

    if wrapper.has_cause?
      wrapper.wrapped_causes.each do |wrapped_cause|
        logger.debug(msg: "Exception has cause",
          exception: wrapped_cause.exception_class_name,
          error: wrapper_cause.message)
      end
    end
  end
end
