RSpec.configure do |config|
  config.before(:each) do
    ActionMailer::Base.deliveries.clear
  end

  config.include Rails.application.routes.url_helpers

  config.before(:each, type: :mailer) do
    # Set default URL options for mailer tests
    Rails.application.routes.default_url_options[:host] = 'localhost:3000'
  end
end
