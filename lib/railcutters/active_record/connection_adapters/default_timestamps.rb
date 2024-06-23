module Railcutters
  module ActiveRecord
    module ConnectionAdapters
      module DefaultTimestamps
        # Always use `CURRENT_TIMESTAMP` as the default for timestamps, so that whenever we create
        # a record outside Rails, it populates the timestamps just as well.
        #
        # See: https://github.com/rails/rails/blob/main/activerecord/lib/active_record/connection_adapters/abstract/schema_definitions.rb#L527
        def timestamps(**options)
          defaults = { default: -> { "CURRENT_TIMESTAMP" } }
          super(**defaults.merge(options))
        end
      end
    end
  end
end
