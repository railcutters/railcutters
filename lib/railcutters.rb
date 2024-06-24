require_relative "railcutters/version"
require_relative "railcutters/allow_sqlite3_v2"
require_relative "railcutters/railtie"

module Railcutters
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
end
