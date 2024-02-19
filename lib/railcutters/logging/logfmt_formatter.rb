module Railcutters
  module Logging
    # Formats a hash-based log entry into a logfmt string
    # The message line has to be a Hash otherwise this won't work
    class LogfmtFormatter < ::Logger::Formatter
      def call(severity, timestamp, progname, payload)
        # Ensure that in the case that payload comes with `ts`, `level` as keys, it won't override them
        # in the final value
        {ts: format_datetime(timestamp), level: severity, tid: payload[:tid], msg: payload[:msg]}
          .compact_blank
          .merge(payload) { |_, main, payload| main }
          .map { |k, v| "#{k}=#{escape_value(v)}" }
          .join(" ") + "\n"
      end

      private

      def escape_value(value)
        value = value.to_s
          .strip
          .gsub(/\s+/, " ")

        # Only add quotes if the value contains spaces, quote or backslashes, and if so we ensure to
        # escape existing quotes and backslashes
        if value.match?(/[ \\"]/)
          value = "\"" + value.gsub(/[\\"]/, "\\\\\\0") + "\""
        end

        value
      end
    end
  end
end
