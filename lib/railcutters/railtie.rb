require "rails/railtie"
require "action_controller/metal/strong_parameters"

module Railcutters
  class Railtie < ::Rails::Railtie
    initializer "railcutters.load_action_controller" do
      return unless config.railcutters.use_params_renamer

      ::ActionController::Parameters.include(ActionController::ParamsRenamer)
    end

    # Settings to allow us to turn individual features on and off
    # ===========================================================

    config.railcutters = ActiveSupport::OrderedOptions.new

    # Enable loading the params renamer, and allows parameters renaming from within controllers
    # using an easy syntax
    config.railcutters.use_params_renamer = true
  end
end
