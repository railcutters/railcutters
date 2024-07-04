require_relative "../support/database_helper"
require "railcutters"

RSpec.describe Railcutters::ActiveRecord::Pagination do
  before(:all) { DatabaseHelper.up }
  after(:all) { DatabaseHelper.down }

  subject(:model_base) do
    DatabaseHelper
      .create_model("Animal") { |t| t.string :name }
      .include(Railcutters::ActiveRecord::Pagination)
  end

  describe "class methods" do
    it ".max_paginates_per sets the max_paginates_per class variable" do
      model_base.max_paginates_per(100)
      expect(model_base.instance_variable_get(:@max_paginates_per)).to eq(100)
    end

    it ".max_pages sets the max_pages class variable" do
      model_base.max_pages(100)
      expect(model_base.instance_variable_get(:@max_pages)).to eq(100)
    end

    it ".paginates_per sets the paginates_per class variable" do
      model_base.paginates_per(100)
      expect(model_base.instance_variable_get(:@paginates_per)).to eq(100)
    end
  end

  it "#page is a shortcut to #paginate(page:)" do
    allow(model_base).to receive(:paginate)

    model_base.page(1)

    expect(model_base).to have_received(:paginate).with(page: 1)
  end

  describe "#paginate" do
    it "accepts being called with named arguments" do
      queries = DatabaseHelper.extract_executed_queries do
        model_base.paginate(page: 2, per_page: 100).to_a
      end

      expect(queries)
        .to include(sql: 'SELECT "animals".* FROM "animals" LIMIT ? OFFSET ?', binds: [100, 100])
    end

    it "accepts being called with a hash as the argument" do
      queries = DatabaseHelper.extract_executed_queries do
        model_base.paginate({page: 2, per_page: 100}).to_a
      end

      expect(queries)
        .to include(sql: 'SELECT "animals".* FROM "animals" LIMIT ? OFFSET ?', binds: [100, 100])
    end

    it "named arguments have precedence over hash arguments" do
      queries = DatabaseHelper.extract_executed_queries do
        model_base.paginate({page: 5, per_page: 10}, page: 1, per_page: 20).to_a
      end

      expect(queries)
        .to include(sql: 'SELECT "animals".* FROM "animals" LIMIT ? OFFSET ?', binds: [20, 0])
    end

    it "uses the default per_page value" do
      queries = DatabaseHelper.extract_executed_queries do
        model_base.paginates_per(10)
        model_base.paginate(page: 1).to_a
      end

      expect(queries)
        .to include(sql: 'SELECT "animals".* FROM "animals" LIMIT ? OFFSET ?', binds: [10, 0])
    end

    it "overrides the default per_page value" do
      queries = DatabaseHelper.extract_executed_queries do
        model_base.paginates_per(10)
        model_base.paginate(page: 1, per_page: 20).to_a
      end

      expect(queries)
        .to include(sql: 'SELECT "animals".* FROM "animals" LIMIT ? OFFSET ?', binds: [20, 0])
    end

    it "allow overriding the per_page up to the max_paginates_per value" do
      queries = DatabaseHelper.extract_executed_queries do
        model_base.max_paginates_per(10)
        model_base.paginate(page: 1, per_page: 20).to_a
      end

      expect(queries)
        .to include(sql: 'SELECT "animals".* FROM "animals" LIMIT ? OFFSET ?', binds: [10, 0])
    end

    it "allows paginating up to the max_pages value" do
      queries = DatabaseHelper.extract_executed_queries do
        model_base.max_pages(10)
        model_base.paginate(page: 20).to_a
      end

      expect(queries)
        .to include(sql: 'SELECT "animals".* FROM "animals" LIMIT ? OFFSET ?', binds: [30, 270])
    end

    it "configures the default max_paginates_per value to the paginates_per value if it's greater" do
      queries = DatabaseHelper.extract_executed_queries do
        model_base.paginates_per(10000)
        model_base.paginate(page: 1, per_page: 200).load
      end

      expect(queries)
        .to include(sql: 'SELECT "animals".* FROM "animals" LIMIT ? OFFSET ?', binds: [200, 0])
    end

    it "paginates starting from index 1" do
      queries = DatabaseHelper.extract_executed_queries do
        model_base.paginate(page: 1).to_a
      end

      expect(queries)
        .to include(sql: 'SELECT "animals".* FROM "animals" LIMIT ? OFFSET ?', binds: [30, 0])
    end

    it "sets the index to 1 when the page is less than 1" do
      queries = DatabaseHelper.extract_executed_queries do
        model_base.paginate(page: -1).to_a
      end

      expect(queries)
        .to include(sql: 'SELECT "animals".* FROM "animals" LIMIT ? OFFSET ?', binds: [30, 0])
    end

    it "sets pagination metadata to the resultset" do
      results = model_base.paginate(page: 1).all

      expect(results.pagination).to eq(page: 1, per_page: 30, total: 0, pages: 0)
    end

    it "counts the total number of records on ungrouped queries by executing a COUNT(*)" do
      queries = DatabaseHelper.extract_executed_queries do
        model_base.paginate(page: 1).to_a
      end

      expect(queries).to include(sql: 'SELECT COUNT(*) FROM "animals"', binds: [])
    end

    it "counts the total number of records on grouped queries by executing a COUNT(*) OVER()" do
      queries = DatabaseHelper.extract_executed_queries do
        model_base.group(:name).paginate(page: 1).to_a
      end

      expect(queries)
        .to include(sql: 'SELECT COUNT(*) OVER () FROM "animals" GROUP BY "animals"."name" LIMIT ?', binds: [1])
    end
  end
end
