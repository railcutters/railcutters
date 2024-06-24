module Railcutters
  module ActiveRecord
    module ConnectionAdapters
      module SQLite3Tuning
        # Ensure we override the existing constants in Rails 8.0+
        # TODO: Remove the `if const_defined?` checks when dropping support for Rails 7.1
        def self.prepended(base)
          base.class_eval { remove_const(:DEFAULT_PRAGMAS) if base.const_defined?(:DEFAULT_PRAGMAS, false) }
          base.class_eval { remove_const(:DEFAULT_CONFIG) if base.const_defined?(:DEFAULT_CONFIG, false) }
        end

        # This is implemented on 8.0+ so we backport it to 7.1
        # See: https://github.com/rails/rails/pull/50371
        # TODO: Remove this when dropping support for Rails 7.1
        DEFAULT_CONFIG = {
          default_transaction_mode: :immediate
        }

        DEFAULT_PRAGMAS = {
          # Enforce and validate FKs
          "foreign_keys" => true,

          # Journal mode WAL allows for greater concurrency (many readers + one writer)
          "journal_mode" => :wal,

          # Avoid FSYNC on the database file on every write and instead only waits for disk writes
          # on WAL, which increases performance while not degrading durability
          "synchronous" => :normal,

          # Enable memory-mapped I/O for I/O intensive operations
          # See: https://sqlite.org/mmap.html
          "mmap_size" => 256.megabytes,

          # Sets an upper bound on the number of auxiliary threads that a prepared statement is
          # allowed to launch to assist with a query.
          "threads" => Etc.nprocessors,

          # Impose a limit on the WAL file to prevent unlimited growth
          "journal_size_limit" => 256.megabytes,

          # Increase the local connection cache to 20.000 pages (each page has 4096 bytes, so in
          # total we could be using up to ~80MB of memory)
          "cache_size" => 20_000,

          # Store temporary tables and indices in memory
          "temp_store" => "MEMORY"
        }

        # We override the connect to ensure we can inject a `DEFAULT_CONFIG` into the connection so
        # we can set SQLite3 specific options.
        # TODO: Remove this when dropping support for Rails 7.1
        def connect
          @raw_connection = self.class.new_client(DEFAULT_CONFIG.merge(@connection_parameters))
        rescue ConnectionNotEstablished => ex
          raise ex.set_pool(@pool)
        end

        # Configure sensible defaults
        #
        # See: https://github.com/oldmoe/litestack/blob/master/lib/litestack/litedb.rb
        def configure_connection
          super

          # Load extensions if specified in the config file
          if @config[:extensions].present?
            @raw_connection.enable_load_extension(true)
            @config[:extensions].each { |path| @raw_connection.load_extension(path) }
            @raw_connection.enable_load_extension(false)
          end

          # Time (in ms) to wait to obtain a write lock before raising an exception.
          # When not explicitely set, define a default value of 5s.
          # Uses sqlite3-ruby busy_handler_timeout which releases GVL between retries
          # See: https://github.com/sparklemotion/sqlite3-ruby/pull/456
          # See: https://github.com/rails/rails/pull/51958
          #
          # TODO: Remove this when dropping support for Rails 7.1
          gem "sqlite3", ">= 2.0"
          if !@config[:timeout].present? && !@config[:retries].present?
            @raw_connection.busy_handler_timeout = 5000
          elsif @config[:timeout].present?
            timeout = self.class.type_cast_config_to_integer(@config[:timeout])
            raise TypeError, "timeout must be integer (in ms), not #{timeout}" unless timeout.is_a?(Integer)
            @raw_connection.busy_handler_timeout = timeout
          end

          # Load pragmas for Rails 7.1 (this is built-in on Rails 8)
          # TODO: Remove this when dropping support for Rails 7.1
          if Gem::Version.new(::Rails.version) < Gem::Version.new("7.2")
            pragmas = @config.fetch(:pragmas, {}).stringify_keys
            DEFAULT_PRAGMAS.merge(pragmas).each do |pragma, value|
              if ::SQLite3::Pragmas.method_defined?(:"#{pragma}=")
                @raw_connection.public_send(:"#{pragma}=", value)
              else
                warn "Unknown SQLite pragma: #{pragma}"
              end
            end
          end
        end
      end
    end
  end
end
