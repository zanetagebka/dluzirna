RSpec.configure do |config|
  config.include Devise::Test::IntegrationHelpers, type: :request
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include Warden::Test::Helpers
  
  # Fix for Rails 8 + Devise session serialization
  config.before(:suite) do
    Warden.test_mode!
  end
  
  config.after(:each) do
    Warden.test_reset!
  end
end