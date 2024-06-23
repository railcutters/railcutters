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
    it "converts the original params of the controller to snake_cased" do
      controller = subject.new
      controller.params = parameters({"ParamsSnakeCased" => [1, 2, 3]})

      expect(controller.process(:action)).to eq(parameters({"params_snake_cased" => [1, 2, 3]}))
    end

    it "converts the params of nested hash parameters to snake_cased" do
      controller = subject.new
      controller.params = ActionController::Parameters.new(
        {"ParamsSnakeCased" => {"NestedParams" => [1, 2, 3]}}
      )

      expect(controller.process(:action)).to eq(
        parameters({"params_snake_cased" => {"nested_params" => [1, 2, 3]}})
      )
    end

    it "converts the params of nested ActionController::Parameters to snake_cased" do
      controller = subject.new
      controller.params = parameters(
        {"ParamsSnakeCased" => {"NestedParams" => [1, 2, 3]}}
      )

      expect(controller.process(:action)).to eq(
        parameters({"params_snake_cased" => {"nested_params" => [1, 2, 3]}})
      )
    end
  end
end
