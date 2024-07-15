require "active_record"

class DatabaseHelper
  @models = {}

  class << self
    attr_accessor :models
  end

  def self.up
    ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
  end

  def self.down
    ActiveRecord::Base.connection_pool.connections.map(&:disconnect!)
    self.models = {}
  end

  # Creates a model on the fly and returns the class reference
  #
  # Alternative gem: https://github.com/Casecommons/with_model
  def self.create_model(name, &migration_block)
    unless self.models[name]
      migration = Class.new(ActiveRecord::Migration[7.1])
      migration.define_method(:change) { create_table(name.tableize, &migration_block) }
      migration.verbose = false
      migration.migrate(:up)
    end

    self.models[name] = eval <<~CLASS
      Class.new(ActiveRecord::Base) do
        def self.name
          "#{name}"
        end
      end
    CLASS
  end

  def self.extract_executed_queries(&block)
    return unless block

    executed_queries = []

    callback = lambda do |_, _, _, _, payload|
      next if payload[:name] == "SCHEMA"
      executed_queries << { sql: payload[:sql], binds: payload[:type_casted_binds] }
    end

    ActiveSupport::Notifications.subscribed(callback, 'sql.active_record', &block)
    executed_queries
  end
end
