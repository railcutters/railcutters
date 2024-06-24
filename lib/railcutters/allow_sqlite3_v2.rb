# Unfortunately we need to resort to this ugly hack to enable support for the gem sqlite3 2.0+ on
# Rails 7.1.
# This is because Rails 7.1 requires sqlite3 ~> 1.4, which prevents us from upgrading it to 2.0.
# See: https://github.com/rails/rails/blob/v7.1.3.4/activerecord/lib/active_record/connection_adapters/sqlite3_adapter.rb
# See: https://github.com/rails/rails/commit/fd1c635d2f1fd8f348ef9fe8a41fb042a8e43482
#
# TODO: Remove this when we drop support for Rails 7.1
require "rails/version"
if ::Gem::Version.new(::Rails.version) < ::Gem::Version.new("7.2")
  ORIGINAL_GEM = method(:gem)

  def gem(*args)
    args[1] = ">= 1.4" if args[0] == "sqlite3"
    ORIGINAL_GEM.call(*args)
  end
end
