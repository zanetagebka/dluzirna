class Admin::DashboardController < Admin::BaseController
  def index
    @total_debts = Debt.count
    @pending_debts = Debt.pending.count
    @overdue_debts = Debt.overdue.count
    @recent_debts = Debt.recent.limit(10)
  end
end