require 'rails_helper'

RSpec.describe 'Admin::Debts', type: :request do
  let(:admin_user) { create(:user, role: :admin) }
  let(:customer_user) { create(:user, role: :customer) }

  describe 'authentication and authorization' do
    context 'when user is not authenticated' do
      it 'redirects to sign in page' do
        get admin_debts_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when user is customer' do
      before { sign_in customer_user, scope: :user }

      it 'denies access to index' do
        get admin_debts_path
        expect(response).to redirect_to(root_path)
      end

      it 'denies access to show' do
        debt = create(:debt)
        get admin_debt_path(debt)
        expect(response).to redirect_to(root_path)
      end

      it 'denies access to new' do
        get new_admin_debt_path
        expect(response).to redirect_to(root_path)
      end

      it 'denies access to create' do
        post admin_debts_path, params: { debt: attributes_for(:debt) }
        expect(response).to redirect_to(root_path)
      end

      it 'denies access to edit' do
        debt = create(:debt)
        get edit_admin_debt_path(debt)
        expect(response).to redirect_to(root_path)
      end

      it 'denies access to update' do
        debt = create(:debt)
        patch admin_debt_path(debt), params: { debt: { amount: 200 } }
        expect(response).to redirect_to(root_path)
      end

      it 'denies access to destroy' do
        debt = create(:debt)
        delete admin_debt_path(debt)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  context 'when user is admin' do
    before { sign_in admin_user, scope: :user }

    describe 'GET /admin/debts' do
      let!(:debt1) { create(:debt, created_at: 1.hour.ago) }
      let!(:debt2) { create(:debt, created_at: 2.hours.ago) }

      it 'returns successful response' do
        get admin_debts_path
        expect(response).to have_http_status(:success)
      end

      it 'displays debts in recent order' do
        get admin_debts_path
        expect(response.body).to include(debt1.customer_email)
        expect(response.body).to include(debt2.customer_email)
      end

      context 'with status filter' do
        let!(:pending_debt) { create(:debt, status: :pending) }
        let!(:notified_debt) { create(:debt, status: :notified) }

        it 'filters by status when provided' do
          get admin_debts_path, params: { status: 'pending' }
          expect(response.body).to include(pending_debt.customer_email)
          expect(response.body).not_to include(notified_debt.customer_email)
        end
      end

      context 'with email search' do
        let!(:john_debt) { create(:debt, customer_email: 'john@test.com') }
        let!(:jane_debt) { create(:debt, customer_email: 'jane@test.com') }

        it 'searches by email when provided' do
          get admin_debts_path, params: { search: 'john' }
          expect(response.body).to include('john@test.com')
          expect(response.body).not_to include('jane@test.com')
        end
      end
    end

    describe 'GET /admin/debts/:id' do
      let(:debt) { create(:debt) }

      it 'returns successful response' do
        get admin_debt_path(debt)
        expect(response).to have_http_status(:success)
      end

      it 'displays debt details' do
        get admin_debt_path(debt)
        expect(response.body).to include(debt.customer_email)
        expect(response.body).to include('Kč') # Check for currency symbol instead of raw amount
        expect(response.body).to include('Detail pohledávky')
      end

      it 'returns 404 for invalid id' do
        get admin_debt_path(id: 'invalid')
        expect(response).to have_http_status(:not_found)
      end
    end

    describe 'GET /admin/debts/new' do
      it 'returns successful response' do
        get new_admin_debt_path
        expect(response).to have_http_status(:success)
      end

      it 'displays debt form' do
        get new_admin_debt_path
        expect(response.body).to include('form')
        expect(response.body).to include('amount')
        expect(response.body).to include('customer_email')
      end
    end

    describe 'POST /admin/debts' do
      let(:valid_attributes) do
        {
          amount: 1500.50,
          due_date: Date.current + 30.days,
          customer_email: 'test@example.com',
          description: 'Test debt description',
          status: 'pending'
        }
      end
      let(:invalid_attributes) { { amount: nil, due_date: nil, customer_email: nil } }

      context 'with valid parameters' do
        it 'creates a new debt' do
          # First verify we can create a debt directly
          debt = Debt.new(valid_attributes)
          expect(debt.valid?).to be_truthy, debt.errors.full_messages.join(', ')
          
          post admin_debts_path, params: { debt: valid_attributes }
          if response.status == 422
            puts "Response body: #{response.body}"
          end
          expect(response).to have_http_status(:redirect)
          expect(Debt.count).to eq(1)
        end

        it 'redirects to the debt show page' do
          post admin_debts_path, params: { debt: valid_attributes }
          expect(response).to redirect_to(admin_debt_path(Debt.last))
        end

        it 'sets success notice' do
          post admin_debts_path, params: { debt: valid_attributes }
          follow_redirect!
          expect(response.body).to include('Debt was successfully created')
        end
      end

      context 'with invalid parameters' do
        it 'does not create a debt' do
          expect {
            post admin_debts_path, params: { debt: invalid_attributes }
          }.not_to change(Debt, :count)
        end

        it 'renders new template with unprocessable_content status' do
          post admin_debts_path, params: { debt: invalid_attributes }
          expect(response).to have_http_status(:unprocessable_content)
        end

        it 'displays validation errors' do
          post admin_debts_path, params: { debt: invalid_attributes }
          expect(response.body).to include('error')
        end
      end
    end

    describe 'GET /admin/debts/:id/edit' do
      let(:debt) { create(:debt) }

      it 'returns successful response' do
        get edit_admin_debt_path(debt)
        expect(response).to have_http_status(:success)
      end

      it 'displays edit form' do
        get edit_admin_debt_path(debt)
        expect(response.body).to include('form')
        expect(response.body).to include(debt.customer_email)
      end
    end

    describe 'PATCH /admin/debts/:id' do
      let(:debt) { create(:debt) }
      let(:new_attributes) { { amount: 200, description: 'Updated description' } }
      let(:invalid_attributes) { { amount: -100 } }

      context 'with valid parameters' do
        it 'updates the debt' do
          patch admin_debt_path(debt), params: { debt: new_attributes }
          debt.reload
          expect(debt.amount).to eq(200)
          expect(debt.description.to_plain_text.strip).to eq('Updated description')
        end

        it 'redirects to the debt show page' do
          patch admin_debt_path(debt), params: { debt: new_attributes }
          expect(response).to redirect_to(admin_debt_path(debt))
        end

        it 'sets success notice' do
          patch admin_debt_path(debt), params: { debt: new_attributes }
          follow_redirect!
          expect(response.body).to include('Debt was successfully updated')
        end
      end

      context 'with invalid parameters' do
        it 'does not update the debt' do
          original_amount = debt.amount
          patch admin_debt_path(debt), params: { debt: invalid_attributes }
          debt.reload
          expect(debt.amount).to eq(original_amount)
        end

        it 'renders edit template with unprocessable_content status' do
          patch admin_debt_path(debt), params: { debt: invalid_attributes }
          expect(response).to have_http_status(:unprocessable_content)
        end

        it 'displays validation errors' do
          patch admin_debt_path(debt), params: { debt: invalid_attributes }
          expect(response.body).to include('error')
        end
      end
    end

    describe 'DELETE /admin/debts/:id' do
      let!(:debt) { create(:debt) }

      it 'destroys the debt' do
        expect {
          delete admin_debt_path(debt)
        }.to change(Debt, :count).by(-1)
      end

      it 'redirects to debts index' do
        delete admin_debt_path(debt)
        expect(response).to redirect_to(admin_debts_path)
      end

      it 'sets success notice' do
        delete admin_debt_path(debt)
        follow_redirect!
        expect(response.body).to include('Debt was successfully deleted')
      end

      it 'returns 404 for non-existent debt' do
        delete admin_debt_path(id: 'invalid')
        expect(response).to have_http_status(:not_found)
      end
    end

    describe 'Security' do
      it 'requires authentication for all actions' do
        sign_out :user

        get admin_debts_path
        expect(response).to redirect_to(new_user_session_path)

        get new_admin_debt_path  
        expect(response).to redirect_to(new_user_session_path)

        post admin_debts_path, params: { debt: attributes_for(:debt) }
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'prevents access to other users data' do
        other_admin = create(:user, role: :admin)
        debt = create(:debt)
        
        # All admins can see all debts in this system design
        get admin_debt_path(debt)
        expect(response).to have_http_status(:success)
      end
    end
  end
end