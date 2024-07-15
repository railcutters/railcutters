require "English"

module Railcutters
  # Inspired by dotenv, a work by Brandon Keepers and contributors.
  # See: https://github.com/bkeepers/dotenv
  module Dotenv
    module Substitutions
      class Variable
        VARIABLE = /
          (\\)?         # is it escaped with a backslash?
          (\$)          # literal $
          (?!\()        # shouldnt be followed by paranthesis
          \{?           # allow brace wrapping
          ([A-Z0-9_]+)? # optional alpha nums
          \}?           # closing brace
        /xi

        def self.call(value, context_env)
          value.gsub(VARIABLE) do |variable|
            match = $LAST_MATCH_INFO

            if match[1] == "\\"
              variable[1..]
            elsif match[3]
              context_env.fetch(match[3], "")
            else
              variable
            end
          end
        end
      end

      class Command
        INTERPOLATED_SHELL_COMMAND = /
          (?<backslash>\\)?   # is it escaped with a backslash?
          \$                  # literal $
          (?<cmd>             # collect command content for eval
            \(                # require opening paren
            (?:[^()]|\g<cmd>)+  # allow any number of non-parens, or balanced
                              # parens (by nesting the <cmd> expression
                              # recursively)
            \)                # require closing paren
          )
        /x

        def self.call(value, _context_env)
          # Process interpolated shell commands
          value.gsub(INTERPOLATED_SHELL_COMMAND) do |*|
            # Eliminate opening and closing parentheses
            command = $LAST_MATCH_INFO[:cmd][1..-2]

            if $LAST_MATCH_INFO[:backslash]
              # Command is escaped, don't replace it.
              $LAST_MATCH_INFO[0][1..]
            else
              # Execute the command and return the value
              `#{command}`.chomp
            end
          end
        end
      end
    end
  end
end
