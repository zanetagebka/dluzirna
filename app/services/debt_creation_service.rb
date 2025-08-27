class DebtCreationService < ApplicationService
  def initialize(debt_params, admin_user)
    @debt_params = debt_params
    @admin_user = admin_user
  end

  def call
    ActiveRecord::Base.transaction do
      create_debt
      send_notification_email
      update_debt_status
    end

    debt
  rescue ActiveRecord::RecordInvalid => e
    raise e
  end

  private

  attr_reader :debt_params, :admin_user
  attr_accessor :debt

  def create_debt
    @debt = Debt.create!(debt_params.merge(admin_user: admin_user))
  end

  def send_notification_email
    DebtNotificationMailer.debt_notification(debt).deliver_now
  end

  def update_debt_status
    debt.update!(status: :notified, notified_at: Time.current)
  end
end
