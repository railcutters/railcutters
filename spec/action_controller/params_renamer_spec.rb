require_relative "../../lib/railcutters/action_controller/params_renamer"

# Require Rails' dependencies
require "active_support"
require "active_support/core_ext"
require "action_controller"

# Helper method to recursively convert a hash to ActionController::Parameters
def parameters(hash)
  to_value = ->(v) do
    case v
    when Array
      v.map { |e| to_value.call(e) }
    when Hash
      parameters(v)
    else
      v
    end
  end

  hash.each do |k, v|
    hash[k] = to_value.call(v)
  end

  ActionController::Parameters.new(hash)
end

RSpec.describe Railcutters::ActionController::ParamsRenamer do
  before { ActionController::Parameters.permit_all_parameters = true }
  after { ActionController::Parameters.permit_all_parameters = false }

  subject do
    Class.new do
      include Railcutters::ActionController::ParamsRenamer
      attr_reader :params

      def initialize(params)
        @params = ActionController::Parameters.new(params)
      end
    end
  end

  describe "#rename!" do
    it "modifies the original parameters" do
      controller = subject.new({"root" => [1, 2, 3]})
      controller.rename!("root" => "newname")

      expect(controller.params).to eq(parameters({"newname" => [1, 2, 3]}))
    end
  end

  describe "#rename" do
    it "does not modify the original parameters" do
      controller = subject.new({"root" => [1, 2, 3]})
      controller.rename("root" => "newname")

      expect(controller.params).to eq(parameters({"root" => [1, 2, 3]}))
    end

    context "when using standard dot notation" do
      it "renames root keys" do
        controller = subject.new({"root" => [1, 2, 3]})
        renamed = controller.rename("root" => "newname")

        expect(renamed).to eq(parameters({"newname" => [1, 2, 3]}))
      end

      it "renames nested keys" do
        controller = subject.new({"root" => {"sublevel" => [1, 2, 3]}})
        renamed = controller.rename("root.sublevel" => "root.newname")

        expect(renamed).to eq(parameters({"root" => {"newname" => [1, 2, 3]}}))
      end

      it "renames keys to increase levels of nesting" do
        controller = subject.new({"root" => [1, 2, 3]})
        renamed = controller.rename("root" => "root.newname")

        expect(renamed).to eq(parameters({"root" => {"newname" => [1, 2, 3]}}))
      end

      it "rename keys to decrease levels of nesting" do
        controller = subject.new({"root" => {"sublevel" => [1, 2, 3]}})
        renamed = controller.rename("root.sublevel" => "root")

        expect(renamed).to eq(parameters({"root" => [1, 2, 3]}))
      end
    end

    context "when using array notation" do
      it "renames root keys" do
        controller = subject.new({"root" => [1, 2, 3]})
        renamed = controller.rename("root[]" => "newname[]")

        expect(renamed).to eq(parameters({"newname" => [1, 2, 3]}))
      end

      it "discard levels of nesting" do
        controller = subject.new({"root" => {"sublevel" => [1, 2, 3]}})
        renamed = controller.rename("root.sublevel[]" => "root[]")

        expect(renamed).to eq(parameters({"root" => [1, 2, 3]}))
      end

      it "adds levels of nesting" do
        controller = subject.new({"root" => [1, 2, 3]})
        renamed = controller.rename("root[]" => "root.newname[]")

        expect(renamed).to eq(parameters({"root" => {"newname" => [1, 2, 3]}}))
      end

      it "overrides existing object" do
        controller = subject.new({"root" => [1, 2, 3], "newname" => {a: 1}})
        renamed = controller.rename("root[]" => "newname[]")

        expect(renamed).to eq(parameters({"newname" => [1, 2, 3]}))
      end

      it "transforms root collections" do
        controller = subject.new({"root" => [{a: 1}, {a: 2}, {a: 3}]})
        renamed = controller.rename("root[].a" => "root[].b")

        expect(renamed).to eq(parameters({"root" => [{b: 1}, {b: 2}, {b: 3}]}))
      end

      it "renames objects with integer keys as if they were arrays" do
        controller = subject.new({"root" => {"0" => {a: 1}, "1" => {a: 2}, "2" => {a: 3}}})
        renamed = controller.rename("root[].a" => "root[].b")

        expect(renamed).to eq(parameters({"root" => {"0" => {b: 1}, "1" => {b: 2}, "2" => {b: 3}}}))
      end
    end
  end
end
