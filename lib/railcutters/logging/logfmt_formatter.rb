module Railcutters
  module Logging
    # Formats a hash-based log entry into a logfmt string
    # The message line has to be a Hash otherwise this won't work
    class LogfmtFormatter < ::Logger::Formatter
      attr_accessor :output_timestamp, :tid_tag

      # Initializes the formatter
      #
      # It will by default format the output using timestamp and a place the tid_tag at the first
      # possible position. The `tid` tag stands for "transaction ID" and is used to identify a
      # unique request or a job execution and it's useful for (distributed) tracing. You can name it
      # however you want, and by default it's named `tid`. It doesn't have to be the same name you
      # use for your HTTP header, for instance, you can use `tid` for the log and `X-Request-ID` for
      # the HTTP header.
      #
      # @param output_timestamp [Boolean] whether to output the timestamp or not
      # @param tid_tag [Symbol] the tag to use for the request ID
      def initialize(output_timestamp: true, tid_tag: :tid)
        super()
        self.output_timestamp = output_timestamp
        self.tid_tag = tid_tag
      end

      def call(severity, timestamp, progname, payload)
        # Ensure that in the case that payload comes with `ts`, `level` as keys, it won't override
        # them in the final value
        tid = {tid_tag => payload[tid_tag]}
        {ts: format_datetime(timestamp), level: severity, **tid, msg: payload[:msg]}
          .compact_blank
          .merge(payload) { |_, main, payload| main }
          .map { |k, v| "#{k}=#{escape_value(v)}" }
          .join(" ") + "\n"
      end

      private

      def format_datetime(timestamp)
        super if output_timestamp
      end

      def escape_value(value)
        # Remove excessive spaces
        value = value.to_s
          .strip
          .gsub(/\s+/, " ")

        # Only add quotes if the value contains spaces, quotes or backslashes, and if so we
        # ensure to escape the quotes and backslashes
        if value.match?(/[ \\"=]/)
          value = "\"" + value.gsub(/[\\"]/, "\\\\\\0") + "\""
        end

        value
      end
    end
  end
end
