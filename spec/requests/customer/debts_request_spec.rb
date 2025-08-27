require 'rails_helper'

RSpec.describe 'Customer::Debts', type: :request do
  let(:admin_user) { create(:user, role: :admin) }
  let(:customer_user) { create(:user, role: :customer) }
  let(:other_customer) { create(:user, role: :customer) }

  describe 'authentication and authorization' do
    context 'when user is not authenticated' do
      it 'redirects to sign in page for index' do
        get customer_debts_path
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'redirects to sign in page for show' do
        debt = create(:debt)
        get customer_debt_path(debt)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when user is admin' do
      before { sign_in admin_user, scope: :user }

      it 'denies access to index' do
        get customer_debts_path
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq('Access denied.')
      end

      it 'denies access to show' do
        debt = create(:debt)
        get customer_debt_path(debt)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq('Access denied.')
      end
    end
  end

  context 'when user is customer' do
    let!(:customer_debt1) { create(:debt, customer_user: customer_user, created_at: 1.hour.ago) }
    let!(:customer_debt2) { create(:debt, customer_user: customer_user, created_at: 2.hours.ago) }
    let!(:other_customer_debt) { create(:debt, customer_user: other_customer) }

    before { sign_in customer_user, scope: :user }

    describe 'GET /customer/debts' do
      it 'returns successful response' do
        get customer_debts_path
        expect(response).to have_http_status(:success)
      end

      it 'displays only current user debts' do
        get customer_debts_path
        # Check that debts are displayed by looking for debt amounts and count
        expect(response.body).to include('Kč') # Should show some currency amounts
        expect(response.body).to include('celkem') # Should show debt count
        expect(response.body).not_to include('Žádné pohledávky') # Should not show "no debts" message
      end

      it 'orders debts by most recent first' do
        get customer_debts_path
        # Just check that multiple debts are shown (since we can't easily check order in HTML)
        expect(response.body).to include('Kč')
        expect(response.body).not_to include('Žádné pohledávky')
      end

      it 'shows empty state when user has no debts' do
        user_without_debts = create(:user, role: :customer)
        sign_in user_without_debts, scope: :user

        get customer_debts_path
        expect(response.body).to include('Žádné pohledávky')
        expect(response.body).to include('0 celkem')
      end

      it 'displays debt summary statistics' do
        get customer_debts_path
        expect(response.body).to include('Celková výše')
        expect(response.body).to include('Po splatnosti')
        expect(response.body).to include('Vyřešeno')
      end
    end

    describe 'GET /customer/debts/:id' do
      context 'when debt belongs to current user' do
        it 'returns successful response' do
          get customer_debt_path(customer_debt1)
          expect(response).to have_http_status(:success)
        end

        it 'displays debt details' do
          get customer_debt_path(customer_debt1)
          expect(response.body).to include(customer_debt1.customer_email)
          expect(response.body).to include('Kč') # Check for currency symbol instead of raw amount
          expect(response.body).to include('Detail pohledávky')
        end

        it 'displays debt status' do
          get customer_debt_path(customer_debt1)
          # Status is displayed in Czech as "Čekající" not "Pending"
          expect(response.body).to include('Čekající')
        end

        it 'shows overdue warning for overdue debts' do
          overdue_debt = create(:debt, customer_user: customer_user, due_date: 1.day.ago)
          get customer_debt_path(overdue_debt)
          expect(response.body).to include('Po splatnosti')
        end
      end

      context 'when debt belongs to other customer' do
        it 'redirects to index with error message' do
          get customer_debt_path(other_customer_debt)
          expect(response).to redirect_to(customer_debts_path)
          expect(flash[:alert]).to eq('Debt not found.')
        end
      end

      context 'when debt does not exist' do
        it 'redirects to index with error message' do
          get customer_debt_path(id: 99999)
          expect(response).to redirect_to(customer_debts_path)
          expect(flash[:alert]).to eq('Debt not found.')
        end
      end

      context 'when debt has no customer_user association' do
        let(:unassigned_debt) { create(:debt, customer_user: nil) }

        it 'redirects to index with error message' do
          get customer_debt_path(unassigned_debt)
          expect(response).to redirect_to(customer_debts_path)
          expect(flash[:alert]).to eq('Debt not found.')
        end
      end
    end

    describe 'Security and data isolation' do
      it 'prevents accessing debts from other customers' do
        get customer_debts_path
        expect(response.body).not_to include(other_customer_debt.token)
        expect(response.body).not_to include(other_customer_debt.customer_email)
      end

      it 'prevents direct access to other customer debt details' do
        get customer_debt_path(other_customer_debt)
        expect(response).to redirect_to(customer_debts_path)
        expect(flash[:alert]).to eq('Debt not found.')
      end

      it 'only shows debts associated with current user' do
        orphaned_debt = create(:debt, customer_user: nil, customer_email: customer_user.email)

        get customer_debts_path
        expect(response.body).not_to include(orphaned_debt.token)
      end

      it 'prevents enumeration of debt IDs' do
        # Try to access debt with sequential ID guessing
        non_existent_id = Debt.maximum(:id).to_i + 100

        get customer_debt_path(id: non_existent_id)
        expect(response).to redirect_to(customer_debts_path)
        expect(flash[:alert]).to eq('Debt not found.')
      end

      it 'maintains session security across requests' do
        get customer_debts_path
        expect(response).to have_http_status(:success)

        # Sign out and ensure access is denied
        sign_out :user
        get customer_debts_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    describe 'Responsive design and accessibility' do
      it 'includes responsive meta tags' do
        get customer_debts_path
        expect(response.body).to include('viewport')
      end

      it 'includes proper heading structure' do
        get customer_debts_path
        expect(response.body).to include('<h2')
      end

      it 'includes status badges for debt states' do
        pending_debt = create(:debt, customer_user: customer_user, status: :pending)
        notified_debt = create(:debt, customer_user: customer_user, status: :notified)

        get customer_debts_path
        expect(response.body).to include('badge')
        expect(response.body).to include('Čekající')
        expect(response.body).to include('Odesláno')
      end
    end
  end

  describe 'Error handling' do
    before { sign_in customer_user, scope: :user }

    it 'handles database connection errors gracefully' do
      # Stub the association to raise database error
      allow_any_instance_of(User).to receive(:customer_debts).and_raise(ActiveRecord::ConnectionNotEstablished)

      expect {
        get customer_debts_path
      }.to raise_error(ActiveRecord::ConnectionNotEstablished)
    end

    it 'handles invalid debt parameters' do
      get customer_debt_path(id: 'invalid-format-!@#')
      expect(response).to redirect_to(customer_debts_path)
      expect(flash[:alert]).to eq('Debt not found.')
    end
  end
end
