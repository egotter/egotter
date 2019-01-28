require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Egotter
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    config.i18n.default_locale = :ja
    config.active_record.raise_in_transactional_callbacks = true
    config.eager_load_paths += %W(#{config.root}/lib)
    config.x.constants = Rails.application.config_for(:constants)
  end
end
