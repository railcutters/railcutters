require_relative "../support/controller_parameters_helper"

require "railcutters"

RSpec.describe Railcutters::ActionController::ParamsRenamer do
  before { ActionController::Parameters.permit_all_parameters = true }
  after { ActionController::Parameters.permit_all_parameters = false }

  subject do
    Class.new(ActionController::Parameters) do
      include Railcutters::ActionController::ParamsRenamer
    end
  end

  describe "#rename!" do
    it "modifies the original parameters" do
      params = subject.new({"root" => [1, 2, 3]})
      params.rename!("root" => "newname")

      expect(params).to eq(parameters({"newname" => [1, 2, 3]}))
    end
  end

  describe "#rename" do
    it "does not modify the original parameters" do
      params = subject.new({"root" => [1, 2, 3]})
      params.rename("root" => "newname")

      expect(params).to eq(parameters({"root" => [1, 2, 3]}))
    end

    context "when using standard dot notation" do
      it "renames root keys" do
        params = subject.new({"root" => [1, 2, 3]})
        renamed = params.rename("root" => "newname")

        expect(renamed).to eq(parameters({"newname" => [1, 2, 3]}))
      end

      it "renames nested keys" do
        params = subject.new({"root" => {"sublevel" => [1, 2, 3]}})
        renamed = params.rename("root.sublevel" => "root.newname")

        expect(renamed).to eq(parameters({"root" => {"newname" => [1, 2, 3]}}))
      end

      it "renames keys to increase levels of nesting" do
        params = subject.new({"root" => [1, 2, 3]})
        renamed = params.rename("root" => "root.newname")

        expect(renamed).to eq(parameters({"root" => {"newname" => [1, 2, 3]}}))
      end

      it "rename keys to decrease levels of nesting" do
        params = subject.new({"root" => {"sublevel" => [1, 2, 3]}})
        renamed = params.rename("root.sublevel" => "root")

        expect(renamed).to eq(parameters({"root" => [1, 2, 3]}))
      end
    end

    context "when using array notation" do
      it "renames root keys" do
        params = subject.new({"root" => [1, 2, 3]})
        renamed = params.rename("root[]" => "newname[]")

        expect(renamed).to eq(parameters({"newname" => [1, 2, 3]}))
      end

      it "discard levels of nesting" do
        params = subject.new({"root" => {"sublevel" => [1, 2, 3]}})
        renamed = params.rename("root.sublevel[]" => "root[]")

        expect(renamed).to eq(parameters({"root" => [1, 2, 3]}))
      end

      it "adds levels of nesting" do
        params = subject.new({"root" => [1, 2, 3]})
        renamed = params.rename("root[]" => "root.newname[]")

        expect(renamed).to eq(parameters({"root" => {"newname" => [1, 2, 3]}}))
      end

      it "overrides existing object" do
        params = subject.new({"root" => [1, 2, 3], "newname" => {a: 1}})
        renamed = params.rename("root[]" => "newname[]")

        expect(renamed).to eq(parameters({"newname" => [1, 2, 3]}))
      end

      it "transforms root collections" do
        params = subject.new({"root" => [{a: 1}, {a: 2}, {a: 3}]})
        renamed = params.rename("root[].a" => "root[].b")

        expect(renamed).to eq(parameters({"root" => [{b: 1}, {b: 2}, {b: 3}]}))
      end

      it "renames objects with integer keys as if they were arrays" do
        params = subject.new({"root" => {"0" => {a: 1}, "1" => {a: 2}, "2" => {a: 3}}})
        renamed = params.rename("root[].a" => "root[].b")

        expect(renamed).to eq(parameters({"root" => {"0" => {b: 1}, "1" => {b: 2}, "2" => {b: 3}}}))
      end
    end
  end
end
