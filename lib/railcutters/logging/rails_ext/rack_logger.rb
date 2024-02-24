# This is a override module to Rails::Rack::Logger to support tagging the logger with the request ID
# as the `tid` and passing the request method and path as the `method` and `path` tags.
#
# It also adds support for using Hash on `config.log_tags` to set custom tags.
module Railcutters::Logging::RailsExt::RackLogger
  def started_request_message(request)
    {
      msg: "Request started",
      method: request.request_method,
      path: request.filtered_path,
      ip: request.ip
    }
  end

  # Supports the following `config.log_tags` (both as a Hash and as an Array)
  #
  # config.log_tags = [:request_id]
  # config.log_tags = [Proc.new { |request| request.request_id }]
  # config.log_tags = {request_id: Proc.new { |request| request.request_id }}
  # config.log_tags = {tid: :request_id, user_id: Proc.new { |request| request.headers["User-ID"]}
  def compute_tags(request)
    Railcutters::Logging::RailsExt.process_default_tags(request, Rails.configuration.log_tags)
  end
end
