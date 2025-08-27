module TestHelpers
  def create_admin_user
    create(:user, :admin)
  end

  def create_customer_user
    create(:user, :customer)
  end

  def create_debt_with_admin
    admin = create_admin_user
    create(:debt, admin_user: admin)
  end
end

RSpec.configure do |config|
  config.include TestHelpers
end
