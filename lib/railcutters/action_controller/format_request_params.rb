require 'active_support/concern'

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
        params.deep_transform_keys!(&:underscore)
      end
    end
  end
end
