module Railcutters
  module ActiveRecord
    module ConnectionAdapters
      module DeferredForeignKey
        # Use deferred foreign keys by default
        #
        # This is supoprted by PostgreSQL and SQLite only. For SQLite, you'll need Rails 7.2+
        #
        # See: https://github.com/rails/rails/blob/main/activerecord/lib/active_record/connection_adapters/abstract/schema_statements.rb#L1152
        def add_foreign_key(from_table, to_table, **options)
          defaults = { deferrable: :deferred }
          super(from_table, to_table, **defaults.merge(options))
        end
      end
    end
  end
end
