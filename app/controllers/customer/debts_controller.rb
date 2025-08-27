class Customer::DebtsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_customer
  before_action :set_debt, only: [ :show ]

  def index
    @debts = current_user.customer_debts.recent
  end

  def show
  end

  private

  def ensure_customer
    redirect_to root_path, alert: "Access denied." unless current_user&.customer?
  end

  def set_debt
    @debt = current_user.customer_debts.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to customer_debts_path, alert: "Debt not found."
  end
end
