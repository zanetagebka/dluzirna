class PublicDebtsController < ApplicationController
  skip_before_action :authenticate_user!
  before_action :set_debt
  before_action :track_debt_view

  def show
    if user_signed_in? && current_user.customer? && @debt.customer_user == current_user
      @debt_data = @debt
      @show_full_details = true
    else
      @debt_data = nil
      @show_full_details = false
    end
  end

  private

  def set_debt
    @debt = Debt.find_by!(token: params[:token])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "Page not found."
  end

  def track_debt_view
    return unless @debt

    if @debt.pending?
      @debt.update_columns(status: :viewed, viewed_at: Time.current)
    end
  end
end
