class ApplicationController < ActionController::Base
  allow_browser versions: :modern
  
  before_action :set_locale
  before_action :authenticate_user!, except: [:show]
  before_action :configure_permitted_parameters, if: :devise_controller?
  
  protected
  
  def set_locale
    I18n.locale = params[:locale] || I18n.default_locale
    I18n.locale = I18n.default_locale unless I18n.available_locales.include?(I18n.locale.to_sym)
  end
  
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:role])
    devise_parameter_sanitizer.permit(:account_update, keys: [:role])
  end
  
  def after_sign_in_path_for(resource)
    if resource.admin?
      admin_root_path
    else
      root_path
    end
  end
  
  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_path, alert: 'Access denied.'
  end
end
