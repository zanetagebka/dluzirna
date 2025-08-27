# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new
    
    if user.admin?
      can :manage, Debt
      can :read, :admin_dashboard
      can :send_manual_email, Debt
      cannot :access, :customer_registration
      cannot :modify, :system_configuration
    elsif user.customer?
      can :read, Debt, customer_user_id: user.id
      can :update, User, id: user.id
      cannot :read, Debt, customer_user_id: { not: user.id }
      cannot :access, :admin_functions
      cannot :create, Debt
      cannot :modify, Debt
      cannot :access, :debt_list_endpoints
    else
      can :read, :homepage
      can :show, :public_debts
      can :access, :registration_page
      cannot :enumerate, :debt_tokens
      cannot :access, :detailed_debt_information
      cannot :read, Debt
    end
  end
end
