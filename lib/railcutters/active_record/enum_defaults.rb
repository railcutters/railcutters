require "active_record/railtie"

module Railcutters
  module ActiveRecord
    module EnumDefaults
      def enum(name = nil, values = nil, **options)
        # Older Rails allowed calling `enum` with keyword args (`enum status: {...}`). That form was
        # deprecated in 7.2 and removed in 8.0. In that shape we can't tell enum definitions from
        # options without whitelisting names, and we don't want to, so we skip our defaults entirely
        # and let Rails handle (and now raise on) that call as it normally would.
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
