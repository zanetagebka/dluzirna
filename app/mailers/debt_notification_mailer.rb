class DebtNotificationMailer < ApplicationMailer
  def debt_notification(debt)
    @debt = debt
    @debt_url = pohledavky_url(@debt.token)
    
    mail(
      to: @debt.customer_email,
      from: 'noreply@dluzirna.cz',
      reply_to: 'support@dluzirna.cz',
      subject: 'Oznámení o dlužné částce / Debt notification'
    )
  end
end
