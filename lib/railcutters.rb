# Railcutters is a collection of opinionated defaults, utilities and enhancements for Rails
# applications. It allows us to leverage the power of Rails while being able to keep some sanity
# while hopping between projects.
#
module Railcutters
  autoload :VERSION, "railcutters/version"

  module ActionController
    autoload :ParamsRenamer, "railcutters/action_controller/params_renamer"
    autoload :FormatRequestParams, "railcutters/action_controller/format_request_params"
    autoload :Pagination, "railcutters/action_controller/pagination"
  end

  module ActiveRecord
    autoload :EnumDefaults, "railcutters/active_record/enum_defaults"
    autoload :Pagination, "railcutters/active_record/pagination"
    autoload :SafeSort, "railcutters/active_record/safe_sort"

    module ConnectionAdapters
      autoload :SQLite3Strictness, "railcutters/active_record/connection_adapters/sqlite3_strictness"
      autoload :SQLite3Tuning, "railcutters/active_record/connection_adapters/sqlite3_tuning"
      autoload :DefaultTimestamps, "railcutters/active_record/connection_adapters/default_timestamps"
      autoload :DeferredForeignKey, "railcutters/active_record/connection_adapters/deferred_foreign_key"
    end
  end

  module Rails
    module Generators
      autoload :VisualizeNulls, "railcutters/rails/generators/visualize_nulls"
    end
  end

  module Logging
    autoload :KVTaggedLogger, "railcutters/logging/kv_tagged_logger"
    autoload :HumanFriendlyFormatter, "railcutters/logging/human_friendly_formatter"
    autoload :LogfmtFormatter, "railcutters/logging/logfmt_formatter"
    autoload :RailsExt, "railcutters/logging/rails_ext"
  end

  autoload :Dotenv, "railcutters/dotenv"
end

# Railtie needs to be loaded immediately after the gem is loaded, so Rails can pick it up and
# process it accordingly.
#
# It's loaded after the autoload definitions so that it can use them without having to use require.
require_relative "railcutters/railtie"

# TODO: Remove this when we drop support for Rails 7.1
require_relative "railcutters/allow_sqlite3_v2"
