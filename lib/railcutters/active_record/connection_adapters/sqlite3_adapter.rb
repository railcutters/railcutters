module Railcutters
  module ActiveRecord
    module ConnectionAdapters
      module SQLite3Adapter
        # Configure sensible defaults
        #
        # See: https://github.com/oldmoe/litestack/blob/master/lib/litestack/litedb.rb
        def configure_connection
          if ::SQLite3::SQLITE_VERSION_NUMBER < 3037000
            raise ActiveRecord::DatabaseConnectionError("SQLite3 version is older than 3.37")
          end

          super

          # Load extensions if specified in the config file
          if @config[:extensions].present?
            @raw_connection.enable_load_extension(true)
            @config[:extensions].each { |path| @raw_connection.load_extension(path) }
            @raw_connection.enable_load_extension(false)
          end

          # Store temporary tables and indices in memory
          @raw_connection.temp_store = "MEMORY"

          # Journal mode WAL allows for greater concurrency (many readers + one writer)
          @raw_connection.journal_mode = "WAL"

          # Avoid FSYNC on the database file on every write and instead only waits for disk writes
          # on WAL, which increases performance while not degrading durability
          @raw_connection.synchronous = "NORMAL"

          # Enforce foreign keys checking (Rails already does that by default but I like keeping it
          # explicit here)
          @raw_connection.foreign_keys = true

          # Tunable settings
          # ================

          # Time (in ms) to wait to obtain a write lock before raising an exception. When not
          # explicitely set, define a default value
          if !@config[:timeout].present? && !@config[:retries].present?
            @raw_connection.busy_timeout = 5000
          end

          # Sets an upper bound on the number of auxiliary threads that a prepared statement is
          # allowed to launch to assist with a query.
          @raw_connection.threads = @config.dig(:pragmas, :threads).presence || Etc.nprocessors

          # Impose a limit on the WAL file to prevent unlimited growth
          @raw_connection.journal_size_limit =
            @config.dig(:pragmas, :journal_size_limit).presence || 256.megabytes

          # Enable memory-mapped I/O for I/O intensive operations
          # See: https://sqlite.org/mmap.html
          @raw_connection.mmap_size = @config.dig(:pragmas, :mmap_size).presence || 256.megabytes

          # Increase the local connection cache to 20.000 pages (each page has 4096 bytes, so in
          # total we could be using up to ~80MB of memory)
          @raw_connection.cache_size = @config.dig(:pragmas, :cache_size).presence || 20_000
        end

        # Adds `STRICT` as the options by default
        # See: https://github.com/rails/rails/blob/main/activerecord/lib/active_record/connection_adapters/abstract/schema_statements.rb#L293
        def create_table(table_name, id: :primary_key, primary_key: nil, force: nil, **options, &block)
          defaults = { options: "STRICT" }
          super(table_name, id:, primary_key:, force:, **detaults.merge(options), &block)
        end

        # SQLite really only does have 4 datatypes: INTEGER, REAL, TEXT and BLOB.
        # All other types gets converted dynamically using their affinity expression, which is
        # able to infer that the field type `VARCHAR` for instance, should be stored in a TEXT
        # column.
        #
        # See: https://www.sqlite.org/datatype3.html
        # See: https://github.com/rails/rails/blob/main/activerecord/lib/active_record/connection_adapters/sqlite3_adapter.rb#L76
        NATIVE_DATABASE_TYPES_OVERRIDES = {
          # Storing date and time fields as TEXT allows the usage of CURRENT_TIMESTAMP, as well as
          # provide better readability when executing queries directly. Most built-in SQLite date
          # and time functions will work as expected.
          #
          # See: https://www.sqlite.org/lang_datefunc.html
          date: { name: "text" },
          time: { name: "text" },
          datetime: { name: "text" },

          # JSON is meant to be stored as TEXT, and SQLite has built-in functions to manipulate them
          # See: https://www.sqlite.org/json1.html
          json: { name: "text" },

          # In SQLite, DECIMAL is not a type, but an affinity. It will use either a INTEGER, REAL
          # or TEXT datatype internally depending on the size of the value. Instead, let's always
          # use TEXT since we're using STRICT mode which requires us to have specific types for
          # the data we're manipulating.
          decimal: { name: "text" },

          # With the addition of STRICT mode, `ANY` is a new type that is more relaxed with data
          # types, giving the user the same behavior as if it were not in STRICT mode.
          #
          # See: https://www.sqlite.org/stricttables.html
          any: { name: "any" },
        }

        def native_database_types
          @_native_database_types ||= NATIVE_DATABASE_TYPES.merge(NATIVE_DATABASE_TYPES_OVERRIDES)
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
