require "active_record/railtie"

module Railcutters
  module ActiveRecord
    module EnumDefaults
      def enum(name = nil, values = nil, **options)
        config = ::Rails.configuration.railcutters
        defaults = config.active_record_enum_defaults.presence || {}

        if config.active_record_enum_use_string_values && values.is_a?(Array)
          values = values.map { |v| [v, v.to_s] }.to_h
        end

        super(name, values, **defaults.merge(options))
      end
    end
  end
end
