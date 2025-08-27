require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'associations' do
    it 'has many customer_debts' do
      association = described_class.reflect_on_association(:customer_debts)
      expect(association.macro).to eq :has_many
      expect(association.options[:class_name]).to eq 'Debt'
      expect(association.options[:foreign_key]).to eq 'customer_user_id'
      expect(association.options[:dependent]).to eq :nullify
    end
  end

  describe 'validations' do
    it 'validates presence of role' do
      user = build(:user, role: nil)
      expect(user).not_to be_valid
      expect(user.errors[:role]).to include("can't be blank")
    end

    it 'validates email format with Devise' do
      user = build(:user, email: 'invalid-email')
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include('is invalid')
    end

    it 'validates password length with Devise' do
      user = build(:user, password: '12345')
      expect(user).not_to be_valid
      expect(user.errors[:password]).to include('is too short (minimum is 6 characters)')
    end
  end

  describe 'enums' do
    it 'defines role enum correctly' do
      expect(User.roles).to eq({ 'admin' => 0, 'customer' => 1 })
    end

    it 'allows setting admin role' do
      user = create(:user, role: :admin)
      expect(user.admin?).to be true
      expect(user.customer?).to be false
    end

    it 'allows setting customer role' do
      user = create(:user, role: :customer)
      expect(user.customer?).to be true
      expect(user.admin?).to be false
    end

    it 'provides role query methods' do
      admin = create(:user, role: :admin)
      customer = create(:user, role: :customer)

      expect(admin).to be_admin
      expect(admin).not_to be_customer
      expect(customer).to be_customer
      expect(customer).not_to be_admin
    end
  end

  describe 'scopes' do
    let!(:admin_user) { create(:user, role: :admin) }
    let!(:customer_user) { create(:user, role: :customer) }
    let!(:unconfirmed_user) { create(:user, role: :customer).tap { |u| u.update_column(:confirmed_at, nil) } }

    describe '.admins' do
      it 'returns only admin users' do
        expect(User.admins).to include(admin_user)
        expect(User.admins).not_to include(customer_user)
        expect(User.admins).not_to include(unconfirmed_user)
      end
    end

    describe '.customers' do
      it 'returns only customer users' do
        expect(User.customers).to include(customer_user)
        expect(User.customers).to include(unconfirmed_user)
        expect(User.customers).not_to include(admin_user)
      end
    end

    describe '.confirmed' do
      it 'returns only confirmed users' do
        expect(User.confirmed).to include(admin_user)
        expect(User.confirmed).to include(customer_user)
        expect(User.confirmed).not_to include(unconfirmed_user)
      end
    end
  end

  describe 'Devise modules' do
    it 'includes database_authenticatable' do
      expect(User.devise_modules).to include(:database_authenticatable)
    end

    it 'includes registerable' do
      expect(User.devise_modules).to include(:registerable)
    end

    it 'includes confirmable' do
      expect(User.devise_modules).to include(:confirmable)
    end

    it 'includes recoverable' do
      expect(User.devise_modules).to include(:recoverable)
    end

    it 'includes rememberable' do
      expect(User.devise_modules).to include(:rememberable)
    end

    it 'includes validatable' do
      expect(User.devise_modules).to include(:validatable)
    end
  end

  describe 'dependent association behavior' do
    it 'nullifies customer_debts when user is destroyed' do
      user = create(:user, role: :customer)
      debt = create(:debt, customer_user: user)

      expect { user.destroy }.to change { debt.reload.customer_user }.from(user).to(nil)
    end
  end
end
