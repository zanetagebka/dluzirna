# Preview all emails at http://localhost:3000/rails/mailers/debt_notification_mailer_mailer
class DebtNotificationMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/debt_notification_mailer_mailer/debt_notification
  def debt_notification
    DebtNotificationMailer.debt_notification
  end
end
