class User < ApplicationRecord
  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :validatable

  has_many :customer_debts, class_name: "Debt", foreign_key: "customer_user_id", dependent: :nullify
  has_many :created_debts, class_name: "Debt", foreign_key: "admin_user_id", dependent: :restrict_with_exception

  enum :role, { admin: 0, customer: 1 }

  validates :role, presence: true

  scope :admins, -> { where(role: :admin) }
  scope :customers, -> { where(role: :customer) }
  scope :confirmed, -> { where.not(confirmed_at: nil) }

  def self.serialize_from_session(key, salt = nil)
    record = to_adapter.get(key)
    record if record && (salt.nil? || record.authenticatable_salt == salt)
  end
end
