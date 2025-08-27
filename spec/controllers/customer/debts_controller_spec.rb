require 'rails_helper'

RSpec.describe Customer::DebtsController, type: :controller do
  let(:admin_user) { create(:user, role: :admin) }
  let(:customer_user) { create(:user, role: :customer) }
  let(:other_customer) { create(:user, role: :customer) }

  describe 'authentication and authorization' do
    context 'when user is not authenticated' do
      it 'redirects to sign in page for index' do
        get :index
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'redirects to sign in page for show' do
        debt = create(:debt)
        get :show, params: { id: debt.id }
        # Should redirect to localized sign-in path
        expect(response.status).to eq(302)
        expect(response).to redirect_to('/uzivatele/prihlaseni')
      end
    end

    context 'when user is admin' do
      before { sign_in admin_user, scope: :user }

      it 'denies access to index' do
        get :index
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq('Access denied.')
      end

      it 'denies access to show' do
        debt = create(:debt)
        get :show, params: { id: debt.id }
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

    describe 'GET #index' do
      it 'returns successful response' do
        get :index
        expect(response).to have_http_status(:success)
      end

      it 'assigns only current user debts' do
        get :index
        expect(assigns(:debts)).to include(customer_debt1, customer_debt2)
        expect(assigns(:debts)).not_to include(other_customer_debt)
      end

      it 'orders debts by most recent first' do
        get :index
        expect(assigns(:debts)).to eq([customer_debt1, customer_debt2])
      end

      it 'shows empty collection when user has no debts' do
        user_without_debts = create(:user, role: :customer)
        sign_in user_without_debts, scope: :user
        
        get :index
        expect(assigns(:debts)).to be_empty
      end
    end

    describe 'GET #show' do
      context 'when debt belongs to current user' do
        it 'returns successful response' do
          get :show, params: { id: customer_debt1.id }
          expect(response).to have_http_status(:success)
        end

        it 'assigns the requested debt' do
          get :show, params: { id: customer_debt1.id }
          expect(assigns(:debt)).to eq(customer_debt1)
        end
      end

      context 'when debt belongs to other customer' do
        it 'redirects to index with error message' do
          get :show, params: { id: other_customer_debt.id }
          expect(response).to redirect_to(customer_debts_path)
          expect(flash[:alert]).to eq('Debt not found.')
        end

        it 'does not assign the debt' do
          get :show, params: { id: other_customer_debt.id }
          expect(assigns(:debt)).to be_nil
        end
      end

      context 'when debt does not exist' do
        it 'redirects to index with error message' do
          get :show, params: { id: 99999 }
          expect(response).to redirect_to(customer_debts_path)
          expect(flash[:alert]).to eq('Debt not found.')
        end
      end

      context 'when debt has no customer_user association' do
        let(:unassigned_debt) { create(:debt, customer_user: nil) }

        it 'redirects to index with error message' do
          get :show, params: { id: unassigned_debt.id }
          expect(response).to redirect_to(customer_debts_path)
          expect(flash[:alert]).to eq('Debt not found.')
        end
      end
    end

    describe 'before_action callbacks' do
      describe '#ensure_customer' do
        it 'allows access for customer users' do
          get :index
          expect(response).not_to redirect_to(root_path)
        end

        it 'blocks access for admin users' do
          sign_in admin_user
          get :index
          expect(response).to redirect_to(root_path)
          expect(flash[:alert]).to eq('Access denied.')
        end

        it 'blocks access when current_user is nil' do
          sign_out :user
          get :index
          expect(response).to redirect_to(new_user_session_path)
        end
      end

      describe '#set_debt' do
        it 'sets debt for show action only' do
          get :show, params: { id: customer_debt1.id }
          expect(assigns(:debt)).to eq(customer_debt1)
        end

        it 'scopes debt to current user only' do
          # Attempt to access another user's debt
          expect {
            get :show, params: { id: other_customer_debt.id }
          }.not_to raise_error

          expect(assigns(:debt)).to be_nil
          expect(response).to redirect_to(customer_debts_path)
        end

        it 'handles RecordNotFound gracefully' do
          get :show, params: { id: 99999 }
          expect(response).to redirect_to(customer_debts_path)
          expect(flash[:alert]).to eq('Debt not found.')
        end
      end
    end

    describe 'security isolation' do
      it 'prevents accessing debts from other customers via association' do
        expect(customer_user.customer_debts).to include(customer_debt1, customer_debt2)
        expect(customer_user.customer_debts).not_to include(other_customer_debt)
      end

      it 'uses scoped queries to prevent data leakage' do
        # Verify that the controller uses current_user.customer_debts
        # rather than Debt.find directly
        get :index
        
        # Check that only user's debts are loaded
        debts = assigns(:debts)
        expect(debts.all? { |debt| debt.customer_user == customer_user }).to be true
      end

      it 'prevents access to debts without customer_user' do
        orphaned_debt = create(:debt, customer_user: nil, customer_email: customer_user.email)
        
        get :show, params: { id: orphaned_debt.id }
        expect(response).to redirect_to(customer_debts_path)
        expect(flash[:alert]).to eq('Debt not found.')
      end
    end
  end

  describe 'access control' do
    describe 'admin user access' do
      before { sign_in admin_user, scope: :user }
      
      it 'redirects admin users from index' do
        get :index
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq('Access denied.')
      end

      it 'redirects admin users from show' do
        debt = create(:debt, customer_user: customer_user)
        get :show, params: { id: debt.id }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq('Access denied.')
      end
    end

    describe 'debt access control' do
      before { sign_in customer_user, scope: :user }
      
      it 'handles missing debt gracefully' do
        get :show, params: { id: 99999 }
        expect(response).to redirect_to(customer_debts_path)
        expect(flash[:alert]).to eq('Debt not found.')
      end

      it 'handles debt from other user' do
        other_debt = create(:debt, customer_user: other_customer)
        get :show, params: { id: other_debt.id }
        expect(response).to redirect_to(customer_debts_path)
        expect(flash[:alert]).to eq('Debt not found.')
      end
    end
  end
end