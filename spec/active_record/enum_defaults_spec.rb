require "railcutters"

RSpec.describe Railcutters::ActiveRecord::EnumDefaults do
  subject do
    # This is a hack to allow us to test the module in isolation, since we can't make assertions
    # to check if the `super` method was called
    parent_enum = Module.new do
      def enum(*, **)
        original_enum(*, **)
      end

      def original_enum(*, **)
      end
    end

    klass = Class.new do
      include parent_enum
      include Railcutters::ActiveRecord::EnumDefaults
    end

    klass.new
  end

  # Helper method to stub the existing configuration
  def stub_config(enum_defaults: {}, use_string_values: false)
    allow(Rails)
      .to receive_message_chain(:configuration, :railcutters, :active_record_enum_defaults)
      .and_return(enum_defaults)
    allow(Rails)
      .to receive_message_chain(:configuration, :railcutters, :active_record_enum_use_string_values)
      .and_return(use_string_values)
  end

  describe "#enum" do
    it "when not using string values, doesn't touch the values array" do
      stub_config(use_string_values: false)
      allow(subject).to receive(:original_enum)

      subject.enum(:name, [:value1, :value2])

      expect(subject).to have_received(:original_enum).with(:name, [:value1, :value2])
    end

    it "when using string values, converts the values array to a hash" do
      stub_config(use_string_values: true)
      allow(subject).to receive(:original_enum)

      subject.enum(:name, [:value1, :value2])

      expect(subject).to have_received(:original_enum).with(:name, {
        value1: "value1",
        value2: "value2"
      })
    end

    context "when not configuring any defaults" do
      it "calls super without additional options" do
        stub_config(enum_defaults: {})
        allow(subject).to receive(:original_enum)

        subject.enum(:name, :values)

        expect(subject).to have_received(:original_enum).with(:name, :values)
      end

      it "allows overriding the defaults" do
        stub_config(enum_defaults: {})
        allow(subject).to receive(:original_enum)

        subject.enum(:name, :values, prefix: true)

        expect(subject).to have_received(:original_enum).with(:name, :values, { prefix: true })
      end
    end

    context "when configuring any defaults" do
      it "calls super without additional options" do
        stub_config(enum_defaults: { prefix: true })
        allow(subject).to receive(:original_enum)

        subject.enum(:name, :values)

        expect(subject).to have_received(:original_enum).with(:name, :values, { prefix: true })
      end

      it "allows overriding the defaults" do
        stub_config(enum_defaults: { prefix: true })
        allow(subject).to receive(:original_enum)

        subject.enum(:name, :values, prefix: false)

        expect(subject).to have_received(:original_enum).with(:name, :values, { prefix: false })
      end
    end
  end
end
