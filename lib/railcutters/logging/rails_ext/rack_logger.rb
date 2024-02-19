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
    hash_tags = {}
    array_tags = []

    @taggers.each do |(key, value)|
      # When calling each on an Array, the variable `key` will actually be the value, while `value`
      # will be null. In this case, we want to use the value as the key and set key to nil.
      key, value = nil, key if value.nil?

      key, value = case value
      # Because this is the default tagger, we want to support it and at the same time rename it to
      # `tid` and not `request_id`
      when :request_id
        [:tid, request.request_id]

      # For all other cases, we just use the key as is, and we support Proc out of the box
      when Proc
        [key, tag.call(request)]
      when Symbol
        [key, request.send(tag)]
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
end
