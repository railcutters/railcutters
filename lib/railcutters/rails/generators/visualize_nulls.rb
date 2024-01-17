module Railcutters
  module Rails
    module Generators
      # Allow explicitly setting null: true/false on attributes for clarity
      module VisualizeNulls
        def options_for_migration
          super.tap do |options|
            options[:null] = !required?
          end
        end
      end
    end
  end
end
