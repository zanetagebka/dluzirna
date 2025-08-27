class Debt < ApplicationRecord
  has_rich_text :description
  
  belongs_to :customer_user, class_name: 'User', optional: true
  belongs_to :admin_user, class_name: 'User', optional: true
  
  validates :amount, :due_date, :customer_email, presence: true
  validates :amount, numericality: { greater_than: 0 }
  validates :customer_email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :token, presence: true, uniqueness: true
  
  enum :status, { pending: 0, notified: 1, viewed: 2, registered: 3, resolved: 4 }
  
  scope :overdue, -> { where('due_date < ?', Date.current) }
  scope :recent, -> { order(created_at: :desc) }
  scope :for_customer, ->(email) { where(customer_email: email) }
  scope :with_includes, -> { includes(:customer_user) }
  scope :search_by_email, ->(email) { where('customer_email ILIKE ?', "%#{email}%") }
  
  before_validation :generate_secure_token, on: :create
  
  def overdue?
    due_date < Date.current
  end
  
  private
  
  def generate_secure_token
    self.token = SecureRandom.urlsafe_base64(32) until token_unique?
  end
  
  def token_unique?
    token.present? && !self.class.exists?(token: token)
  end
  
  def schedule_notification_email
    DebtNotificationMailer.delay.debt_notification(self)
  end
end
