require_relative "railcutters/version"
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
  end

  module Logging
    autoload :KVTaggedLogger, "railcutters/logging/kv_tagged_logger"
    autoload :HumanFriendlyFormatter, "railcutters/logging/human_friendly_formatter"
    autoload :LogfmtFormatter, "railcutters/logging/logfmt_formatter"
    autoload :RailsExt, "railcutters/logging/rails_ext"
  end
end
