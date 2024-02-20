require "active_support/isolated_execution_state"

module Railcutters
  module Logging
    # Drop-in thread-safe replacement for ActiveSupport::TaggedLogging that generates log entries as
    # hashes to be used with formatters that take hashes as input.
    #
    # Usage:
    #  ```ruby
    #  logger = Railcutters::KVTaggedLogger.new($stdout)
    #  logger.tagged(foo: "bar") do
    #    logger.info("Hello world")
    #  end
    #  logger.tagged(foo: "notbar").warn("Hello!")
    #  ```
    #
    class KVTaggedLogger < ::Logger
      def initialize(*, **)
        super
        ObjectSpace.define_finalizer(self, self.class.method(:finalize))
      end

      def self.finalize(object_id)
        ActiveSupport::IsolatedExecutionState.delete(:"hash_tagged_logger_#{object_id}_tags")
      end

      def tags
        ActiveSupport::IsolatedExecutionState[:"hash_tagged_logger_#{object_id}_tags"] ||= []
      end

      protected def tags=(tags)
        ActiveSupport::IsolatedExecutionState[:"hash_tagged_logger_#{object_id}_tags"] = tags
      end

      def clone
        super.tap do |logger|
          logger.tags = tags.dup
        end
      end

      def tagged(*tags)
        if block_given?
          begin
            push_tags(*tags)
            yield self
          ensure
            pop_tags(tags.length)
          end
        else
          logger = clone
          logger.push_tags(*tags)
          logger
        end
      end

      # Compatibility with ActiveSupport::TaggedLogging

      def push_tags(*new_tags)
        tags.concat(new_tags.flatten.compact_blank)
      end

      def pop_tags(count)
        tags.pop(count)
      end

      def clear_tags!
        tags.clear
      end

      alias_method :flush, :clear_tags!

      private

      def format_message(severity, datetime, progname, entry)
        return if entry.nil?

        if entry.is_a?(String)
          entry = {msg: entry}
        elsif entry.respond_to?(:transform_keys)
          entry = entry.transform_keys(&:to_sym)
        else
          raise ArgumentError, "entry must be a String or a Hash"
        end

        (@formatter || @default_formatter)
          .call(severity, datetime, progname, processed_tags.merge(entry))
      end

      # Generates a hash from existing tags array
      #
      # It never overrides the `tid` tag if it's already set. For example, in a synchronous job
      # execution (when using `perform_now` during a request), the `tid` tag will be kept to the
      # previously set request ID.
      def processed_tags
        unnamed_tags = 0
        tags.each_with_object({}) do |tag, hash|
          current_tid = hash[:tid]

          if tag.is_a?(Hash)
            hash.merge!(tag.transform_keys(&:to_sym))
          elsif tag.is_a?(String) && tag.include?("=")
            key, value = tag.split("=", 2)
            hash[key.to_sym] = value
          else
            tagname = "tag#{unnamed_tags += 1}"
            hash[tagname.to_sym] = tag
          end

          hash[:tid] = current_tid if current_tid
        end
      end
    end
  end
end
