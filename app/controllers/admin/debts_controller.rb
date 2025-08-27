class Admin::DebtsController < Admin::BaseController
  before_action :set_debt, only: [:show, :edit, :update, :destroy]
  
  def index
    @debts = Debt.with_includes
                 .recent
                 .page(params[:page])
                 .per(25)
    
    @debts = @debts.where(status: params[:status]) if params[:status].present?
    @debts = @debts.search_by_email(params[:search]) if params[:search].present?
  end
  
  def show
  end
  
  def new
    @debt = Debt.new
  end
  
  def create
    @debt = DebtCreationService.call(debt_params, current_user)
    
    redirect_to admin_debt_path(@debt), notice: 'Debt was successfully created.'
  rescue ActiveRecord::RecordInvalid => e
    @debt = e.record
    render :new, status: :unprocessable_entity
  end
  
  def edit
  end
  
  def update
    if @debt.update(debt_params)
      if params[:debt][:send_notification] == "1"
        DebtNotificationMailer.debt_notification(@debt).deliver_now
      end
      
      redirect_to admin_debt_path(@debt), notice: 'Debt was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end
  
  def destroy
    @debt.destroy!
    redirect_to admin_debts_path, notice: 'Debt was successfully deleted.'
  end
  
  private
  
  def set_debt
    @debt = Debt.find(params[:id])
  end
  
  def debt_params
    params.require(:debt).permit(:amount, :due_date, :customer_email, :description, :status)
  end
end