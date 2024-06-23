require_relative "../../lib/railcutters/action_controller/format_request_params"
require_relative "../support/controller_parameters_helper"
require "action_controller"

RSpec.describe Railcutters::ActionController::FormatRequestParams do
  subject do
    Class.new(ActionController::Metal) do
      include ::AbstractController::Callbacks
      include Railcutters::ActionController::FormatRequestParams

      def initialize
        super
        self.request = ActionDispatch::Request.new({})
        self.response = ActionDispatch::Response.new
      end

      def action
        params
      end
    end
  end

  describe "#params" do
    it "modifies the original params of the controller" do
      controller = subject.new
      controller.params = parameters({"ParamsSnakeCased" => [1, 2, 3]})

      expect(controller.process(:action)).to eq(parameters({"params_snake_cased" => [1, 2, 3]}))
    end

    it "modifies the params of nested parameters as a hash" do
      controller = subject.new
      controller.params = ActionController::Parameters.new(
        {"ParamsSnakeCased" => {"NestedParams" => [1, 2, 3]}}
      )

      expect(controller.process(:action)).to eq(
        parameters({"params_snake_cased" => {"nested_params" => [1, 2, 3]}})
      )
    end

    # It's not possible to modify the params of nested parameters as ActionController::Parameters
    # yet, but it doesn't seem to be a problem as Rails' root params will always convert the nested
    # ones into a hash. I'm keeping this test here just in case we ever need to modify the nested
    # behavior.
    it "[currently] does not modify the params of nested params as ActionController::Parameters" do
      controller = subject.new
      controller.params = parameters(
        {"ParamsSnakeCased" => {"NestedParams" => [1, 2, 3]}}
      )

      expect(controller.process(:action)).to eq(
        parameters({"params_snake_cased" => {"NestedParams" => [1, 2, 3]}})
      )
    end
  end
end
