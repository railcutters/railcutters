module Railcutters
  module Logging
    # Formats a hash-based log entry into a human-friendly string
    # The message line has to be a Hash otherwise this won't work
    class HumanFriendlyFormatter < ::Logger::Formatter
      attr_accessor :colorize_logging, :tid_tag, :tid_strlimit

      # ANSI sequence modes
      MODES = {
        clear: 0,
        bold: 1,
        italic: 3,
        underline: 4
      }

      # ANSI sequence colors
      BLACK = "\e[30m"
      RED = "\e[31m"
      GREEN = "\e[32m"
      YELLOW = "\e[33m"
      BLUE = "\e[34m"
      MAGENTA = "\e[35m"
      CYAN = "\e[36m"
      WHITE = "\e[37m"

      # Initializes the formatter
      #
      # It will by default format the output using timestamp and a place the tid_tag at the first
      # possible position. The `tid` tag stands for "transaction ID" and is used to identify a
      # unique request or a job execution and it's useful for (distributed) tracing. You can name it
      # however you want, and by default it's named `tid`. It doesn't have to be the same name you
      # use for your HTTP header, for instance, you can use `tid` for the log and `X-Request-ID` for
      # the HTTP header.
      #
      # @param colorize_logging [Boolean] whether to colorize the output or not
      # @param datetime_format [String] the format to use for the timestamp
      # @param tid_tag [Symbol] the tag to use for the request ID/job ID
      # @param tid_strlimit [Integer] the maximum length of the request ID/job ID to display
      def initialize(colorize_logging: true, datetime_format: "%H:%M:%S.%3N", tid_tag: :tid, tid_strlimit: 8)
        super()
        self.colorize_logging = colorize_logging
        self.datetime_format = datetime_format
        self.tid_tag = tid_tag
        self.tid_strlimit = tid_strlimit
      end

      def call(severity, timestamp, progname, payload)
        log_line = format_datetime(timestamp) + " " + format_level(severity)
        if payload[tid_tag]
          tid = payload[tid_tag]
          tid = tid.slice(0, tid_strlimit) if tid_strlimit
          log_line += " " + colorize("[#{tid}]", :magenta)
        end
        log_line += " " + payload[:msg].strip

        extra = payload.except(:msg, tid_tag).map do |k, v|
          colorize(k, nil, bold: true) +
            colorize("=", :blue, bold: true) +
            colorize(v, nil, italic: true)
        end.join(" ")
        if extra.present?
          log_line += " " + extra
        end

        log_line + "\n"
      end

      private

      def format_level(severity)
        case severity
        when "DEBUG" then colorize("DEBUG", :blue, bold: true)
        when "INFO" then colorize(" INFO", :green, bold: true)
        when "WARN" then colorize(" WARN", :yellow, bold: true)
        when "ERROR" then colorize("ERROR", :red, bold: true)
        when "FATAL" then colorize("FATAL", :red, bold: true)
        when "UNKNOWN" then colorize("UNKNOWN", :magenta, bold: true)
        end
      end

      # Set color by using a symbol or one of the defined constants. Set modes
      # by specifying bold, italic, or underline options. Inspired by Highline,
      # this method will automatically clear formatting at the end of the returned String.
      def colorize(text, color, mode_options = {})
        return text unless colorize_logging
        color = self.class.const_get(color.upcase) if color.is_a?(Symbol)
        mode = mode_from(mode_options)
        clear = "\e[#{MODES[:clear]}m"
        "#{mode}#{color}#{text}#{clear}"
      end

      def mode_from(options)
        modes = MODES.values_at(*options.compact_blank.keys)

        "\e[#{modes.join(";")}m" if modes.any?
      end
    end
  end
end
