module Railcutters
  module ActiveRecord
    module ConnectionAdapters
      module SQLite3Strictness
        # Ensure we have the correct version of SQLite
        def configure_connection
          # SQLite 3.37 is required for the `STRICT` option
          if ::SQLite3::SQLITE_VERSION_NUMBER < 3037000
            raise ActiveRecord::DatabaseConnectionError("SQLite3 version is older than 3.37")
          end

          super
        end

        # Adds `STRICT` as the options by default
        # See: https://github.com/rails/rails/blob/main/activerecord/lib/active_record/connection_adapters/abstract/schema_statements.rb#L293
        def create_table(table_name, id: :primary_key, primary_key: nil, force: nil, **options, &block)
          defaults = { options: "STRICT" }
          super(table_name, id:, primary_key:, force:, **defaults.merge(options), &block)
        end

        # SQLite really only does have 4 datatypes: INTEGER, REAL, TEXT and BLOB.
        # All other types gets converted dynamically using their affinity expression, which is
        # able to infer that the field type `VARCHAR` for instance, should be stored in a TEXT
        # column.
        #
        # See: https://www.sqlite.org/datatype3.html
        # See: https://github.com/rails/rails/blob/main/activerecord/lib/active_record/connection_adapters/sqlite3_adapter.rb#L76
        NATIVE_DATABASE_TYPES_OVERRIDES = {
          # Override string as by default it uses "varchar" which is not a valid SQLite strict type
          string: { name: "text" },

          # Use REAL for float fields
          float: { name: "real" },

          # In SQLite, DECIMAL is not a type, but an affinity. It will use either a INTEGER, REAL
          # or TEXT datatype internally depending on the size of the value. Instead, let's always
          # use TEXT since we're using STRICT mode which requires us to have specific types for
          # the data we're manipulating.
          decimal: { name: "text" },

          # Storing date and time fields as TEXT allows the usage of CURRENT_TIMESTAMP, as well as
          # provide better readability when executing queries directly. Most built-in SQLite date
          # and time functions will work as expected.
          #
          # See: https://www.sqlite.org/lang_datefunc.html
          date: { name: "text" },
          time: { name: "text" },
          datetime: { name: "text" },

          # Use INTEGER for boolean fields, since SQLite does not have a native boolean type.
          boolean: { name: "integer" },

          # JSON is meant to be stored as TEXT, and SQLite has built-in functions to manipulate them
          # See: https://www.sqlite.org/json1.html
          json: { name: "text" },
          jsonb: { name: "blob" },

          # With the addition of STRICT mode, `ANY` is a new type that is more relaxed with data
          # types, giving the user the same behavior as if it were not in STRICT mode.
          #
          # See: https://www.sqlite.org/stricttables.html
          any: { name: "any" },
        }

        def native_database_types
          @_native_database_types ||=
            ::ActiveRecord::ConnectionAdapters::SQLite3Adapter::NATIVE_DATABASE_TYPES
            .merge(NATIVE_DATABASE_TYPES_OVERRIDES)
        end

        # Rails sets this to true, but this is actually false for SQLite, which does not support
        # precision at all
        #
        # See: https://github.com/rails/rails/blob/main/activerecord/lib/active_record/connection_adapters/abstract/schema_definitions.rb#L452
        def supports_datetime_with_precision?
          false
        end
      end
    end
  end
end
