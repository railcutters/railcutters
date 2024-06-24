require "active_record/railtie"

module Railcutters
  module ActiveRecord
    module EnumDefaults
      def enum(name = nil, values = nil, **options)
        # This is a workaround for a deprecated behavior on 7.3+
        # On Rails 7.0, it was possible to call `enum` with keyword args, but on 8.0+ it is being
        # deprecated. When using this syntax, we can't infer whether the user is trying to set
        # enum definitions or options without whitelisting names especifically, and we don't want to
        # do that since this syntax is deprecated anyway.
        #
        # What we'll do is to ignore the defaults altogether when using this syntax, and let Rails
        # handle it as it normally would.
        #
        # See: https://github.com/rails/rails/commit/8c5425197c7969ff50f675e9792fce1998fb9bc2
        if name.nil? && values.nil? && options.is_a?(Hash)
          return super
        end

        config = ::Rails.configuration.railcutters
        defaults = config.ar_enum_defaults.presence || {}

        if config.ar_enum_string_values && values.is_a?(Array)
          values = values.map { |v| [v, v.to_s] }.to_h
        end

        super(name, values, **defaults.merge(options))
      end
    end
  end
end
