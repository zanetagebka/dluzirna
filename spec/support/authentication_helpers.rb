module AuthenticationHelpers
  # Sign in an admin user for controller specs
  def sign_in_admin(admin = nil)
    admin ||= create(:user, :admin)
    sign_in admin
    admin
  end

  # Sign in a customer user for controller specs
  def sign_in_customer(customer = nil)
    customer ||= create(:user, :customer)
    sign_in customer
    customer
  end

  # Create and sign in admin for request specs
  def request_sign_in_admin(admin = nil)
    admin ||= create(:user, :admin)
    post user_session_path, params: {
      user: {
        email: admin.email,
        password: admin.password
      }
    }
    admin
  end

  # Create and sign in customer for request specs
  def request_sign_in_customer(customer = nil)
    customer ||= create(:user, :customer)
    post user_session_path, params: {
      user: {
        email: customer.email,
        password: customer.password
      }
    }
    customer
  end
end