require_relative "boot"

require "rails/all"

Bundler.require(*Rails.groups)

module Dluzirna
  class Application < Rails::Application
    config.load_defaults 8.0

    config.autoload_lib(ignore: %w[assets tasks])

    config.time_zone = "Prague"
    config.i18n.default_locale = :cs
    config.i18n.available_locales = [:cs, :en]
    config.i18n.fallbacks = [I18n.default_locale]
    config.middleware.use Rack::Attack
  end
end
