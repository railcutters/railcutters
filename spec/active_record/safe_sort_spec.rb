require "railcutters"

RSpec.describe Railcutters::ActiveRecord::SafeSort do
  subject(:model_base) do
    Class.new do
      def self.scope(name, body)
        define_method(name, &body)
      end

      def order(*args)
      end

      include Railcutters::ActiveRecord::SafeSort
    end
  end

  subject(:model_instance) do
    Class.new(model_base) { safe_sortable_columns :name, :age }
      .new
      .tap { |instance| allow(instance).to receive(:order) }
  end

  describe ".safe_sortable_columns" do
    it "sets the safe_sortable_columns class variable" do
      model_base.safe_sortable_columns(:name, "joined_table.subcolumn")

      expect(model_base.instance_variable_get(:@safe_sortable_columns))
        .to eq([:name, "joined_table.subcolumn"])
    end
  end

  describe "#safe_sort" do
    it "sorts a field when the field is allowed" do
      model_instance.safe_sort(:name, :asc)

      expect(subject).to have_received(:order).with(name: :asc)
    end

    it "sorts a field when the field is allowed in descending order" do
      model_instance.safe_sort(:name, :desc)

      expect(subject).to have_received(:order).with(name: :desc)
    end

    it "sorts ascending when the direction is not specified" do
      model_instance.safe_sort(:name)

      expect(subject).to have_received(:order).with(name: :asc)
    end

    it "sorts ascending when the direction is unknown" do
      model_instance.safe_sort(:name, "whatever")

      expect(subject).to have_received(:order).with(name: :asc)
    end

    it "does not sort a field when the field is not allowed and a default is not present" do
      model_instance.safe_sort(:not_allowed, :asc)

      expect(subject).not_to have_received(:order)
    end

    it "sorts a field when not allowed but a default is present" do
      model_instance.safe_sort(:not_allowed, :asc, default: :name)

      expect(subject).to have_received(:order).with(name: :asc)
    end

    it "sorts a field when not allowed using an invalid order but a default is present" do
      model_instance.safe_sort(:not_allowed, :what, default: :name, default_order: :desc)

      expect(subject).to have_received(:order).with(name: :desc)
    end

    it "sorts a field using a column list override" do
      model_instance.safe_sort(:color, :asc, only_columns: [:color])

      expect(subject).to have_received(:order).with(color: :asc)
    end
  end
end
