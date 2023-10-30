require "rails/railtie"

module Railcutters
  class Railtie < ::Rails::Railtie
    initializer "railcutters.load_action_controller" do
      return unless config.railcutters.use_params_renamer

      ActiveSupport.on_load(:action_controller) do
        include(ActionController::ParamsRenamer)
      end
    end

    config.railcutters = ActiveSupport::OrderedOptions.new

    # Enable loading the params renamer, and allows parameters renaming from within controllers
    # using an easy syntax
    config.railcutters.use_params_renamer = true
  end
end
