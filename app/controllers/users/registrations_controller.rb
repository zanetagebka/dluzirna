class Users::RegistrationsController < Devise::RegistrationsController
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :ensure_admin_for_destroy, only: [ :destroy ]

  def destroy
    Rails.logger.info "Admin user #{current_user.email} deleted account #{resource.email}"
    super
  end

  protected

  def ensure_admin_for_destroy
    unless current_user&.admin?
      redirect_to edit_user_registration_path, alert: "Nemáte oprávnění k zrušení účtu. Kontaktujte administrátora."
    end
  end

  def configure_permitted_parameters
    # Don't permit role parameter for sign_up - all web registrations are customers
    devise_parameter_sanitizer.permit(:sign_up, keys: [])
    devise_parameter_sanitizer.permit(:account_update, keys: [])
  end

  private

  def build_resource(hash = {})
    # Force all web registrations to be customer role
    hash[:role] = :customer if action_name == "create"
    super(hash)
  end
end
