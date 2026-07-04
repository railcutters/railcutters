require_relative "../support/database_helper"
require "railcutters"

RSpec.describe Railcutters::ActiveRecord::SafeSort do
  before(:all) { DatabaseHelper.up }
  after(:all) { DatabaseHelper.down }

  subject(:model) do
    DatabaseHelper
      .create_model("User") { |t| t.string :name; t.integer :age; t.string :color }
      .include(Railcutters::ActiveRecord::SafeSort)
      .tap { |m| m.safe_sortable_columns :name, :age }
  end

  # Runs the scope against a real model while spying on the `order` call it issues, and returns
  # the spied relation. A real ActiveRecord model (not a double) is required: inside a scope block
  # `self` is the Relation, so the allowed columns are only found when read from `klass` (the model).
  def order_spy(*args, **kwargs)
    relation = model.all
    allow(model).to receive(:all).and_return(relation)
    allow(relation).to receive(:order)
    model.safe_sort(*args, **kwargs)
    relation
  end

  describe ".safe_sortable_columns" do
    it "sets the safe_sortable_columns class variable" do
      model.safe_sortable_columns(:name, "joined_table.subcolumn")

      expect(model.instance_variable_get(:@safe_sortable_columns))
        .to eq([:name, "joined_table.subcolumn"])
    end
  end

  describe ".safe_sort" do
    it "orders by a field when the field is allowed" do
      expect(order_spy(:name, :asc)).to have_received(:order).with(name: :asc)
    end

    it "orders by a field when the field is allowed in descending order" do
      expect(order_spy(:name, :desc)).to have_received(:order).with(name: :desc)
    end

    it "orders by any allowed column, not only the first one" do
      expect(order_spy(:age, :desc)).to have_received(:order).with(age: :desc)
    end

    it "orders ascending when the direction is not specified" do
      expect(order_spy(:name)).to have_received(:order).with(name: :asc)
    end

    it "orders ascending when the direction is unknown" do
      expect(order_spy(:name, "whatever")).to have_received(:order).with(name: :asc)
    end

    it "does not order when the field is not allowed and a default is not present" do
      expect(order_spy(:not_allowed, :asc)).not_to have_received(:order)
    end

    it "orders by the default when the field is not allowed but a default is present" do
      expect(order_spy(:not_allowed, :asc, default: :name)).to have_received(:order).with(name: :asc)
    end

    it "orders by the default_order when falling back to the default" do
      expect(order_spy(:not_allowed, :what, default: :name, default_order: :desc))
        .to have_received(:order).with(name: :desc)
    end

    it "orders by a field using a column list override" do
      expect(order_spy(:color, :asc, only_columns: [:color])).to have_received(:order).with(color: :asc)
    end
  end
end
