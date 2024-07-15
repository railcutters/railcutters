module Railcutters
  # Inspired by dotenv, a work by Brandon Keepers and contributors.
  # See: https://github.com/bkeepers/dotenv
  module Dotenv
    module_function

    autoload :Parser, "railcutters/dotenv/parser"
    autoload :FormatError, "railcutters/dotenv/parser"

    module Substitutions
      autoload :Variable, "railcutters/dotenv/substitutions"
      autoload :Command, "railcutters/dotenv/substitutions"
    end

    # Loads environment variables from one or more `.env` files. See `#parse` for more details.
    def load(*filenames, overwrite: false, ignore: true)
      update(parse(*filenames, ignore:), overwrite:)
    end

    # Parses the given files, yielding for each file if a block is given.
    #
    # @param filenames [String, Array<String>] Files to parse
    # @param overwrite [Boolean] Overwrite existing `ENV` values
    # @param ignore [Boolean] Ignore non-existent files
    # @return [Hash] parsed key/value pairs
    def parse(*filenames, ignore: false)
      filenames.reduce({}) do |hash, filename|
        begin
          env = Parser.new(File.read(filename)).parse
        rescue Errno::ENOENT
          raise unless ignore
        end

        hash.merge!(env || {})
      end
    end

    # Update `ENV` with the given hash of keys and values
    #
    # @param env [Hash] Hash of keys and values to set in `ENV`
    # @param overwrite [Boolean] Overwrite existing `ENV` values
    def update(env = {}, overwrite: true)
      ENV.update(env.transform_keys(&:to_s)) do |key, old_value, new_value|
        # This block is called when a key exists. Return the new value if overwrite is true.
        overwrite ? new_value : old_value
      end
    end
  end
end
