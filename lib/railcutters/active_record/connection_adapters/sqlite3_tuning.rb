module Railcutters
  module ActiveRecord
    module ConnectionAdapters
      module SQLite3Tuning
        # Rails ships its own tuned SQLite pragmas and, in `configure_connection`, merges any
        # `pragmas:` from database.yml over them. We remove Rails' constant so that reference
        # resolves - via ancestor lookup on the prepended module - to our richer defaults below.
        # This layers our extra defaults underneath whatever the app sets in database.yml, without
        # having to override any adapter method: immediate transactions, extension loading and the
        # busy timeout are all handled natively by Rails.
        def self.prepended(base)
          base.remove_const(:DEFAULT_PRAGMAS)
        end

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
      end
    end
  end
end
