require "active_support/concern"
require "active_support/core_ext/module/delegation"
require "active_support/core_ext/module/attribute_accessors"
require "action_controller/metal/strong_parameters"

module Railcutters
  module ActionController
    # Automatically formats the request param keys according to our standard, so that keys are always
    # camelCased on client-end and snake_cased on Rails side.
    # For the response, we have Jbuilder configured at `config/initializers/json_param_key_transform.rb`
    module FormatRequestParams
      extend ActiveSupport::Concern

      included do
        before_action :underscore_params!
      end

      private

      def underscore_params!
        _deep_transform_keys_in_object!(params, &:underscore)
      end

      def _deep_transform_keys_in_object!(object, &block)
        case object
        when Hash, ::ActionController::Parameters
          object.keys.each do |key|
            value = object.delete(key)
            object[yield(key)] = _deep_transform_keys_in_object!(value, &block)
          end
          object
        when Array
          object.map! { |e| _deep_transform_keys_in_object!(e, &block) }
        else
          object
        end
      end
    end
  end
end
