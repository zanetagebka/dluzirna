require 'rails_helper'

RSpec.describe Admin::DebtsController, type: :controller do
  let(:admin_user) { create(:user, role: :admin) }
  let(:customer_user) { create(:user, role: :customer) }

  describe 'authentication and authorization' do
    context 'when user is not authenticated' do
      it 'redirects to sign in page' do
        get :index
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when user is customer' do
      before { sign_in customer_user, scope: :user }

      it 'denies access to index' do
        get :index
        expect(response).to redirect_to(root_path)
      end

      it 'denies access to show' do
        debt = create(:debt)
        get :show, params: { id: debt.id }
        expect(response).to redirect_to(root_path)
      end

      it 'denies access to new' do
        get :new
        expect(response).to redirect_to(root_path)
      end

      it 'denies access to create' do
        post :create, params: { debt: attributes_for(:debt) }
        expect(response).to redirect_to(root_path)
      end

      it 'denies access to edit' do
        debt = create(:debt)
        get :edit, params: { id: debt.id }
        expect(response).to redirect_to(root_path)
      end

      it 'denies access to update' do
        debt = create(:debt)
        patch :update, params: { id: debt.id, debt: { amount: 200 } }
        expect(response).to redirect_to(root_path)
      end

      it 'denies access to destroy' do
        debt = create(:debt)
        delete :destroy, params: { id: debt.id }
        expect(response).to redirect_to(root_path)
      end
    end
  end

  context 'when user is admin' do
    before { sign_in admin_user, scope: :user }

    describe 'GET #index' do
      let!(:debt1) { create(:debt, created_at: 1.hour.ago) }
      let!(:debt2) { create(:debt, created_at: 2.hours.ago) }

      it 'returns successful response' do
        get :index
        expect(response).to have_http_status(:success)
      end

      it 'assigns debts in recent order' do
        get :index
        expect(assigns(:debts)).to eq([debt1, debt2])
      end

      it 'uses pagination with 25 per page' do
        26.times { create(:debt) }
        get :index
        expect(assigns(:debts).size).to eq(25)
      end

      context 'with status filter' do
        let!(:pending_debt) { create(:debt, status: :pending) }
        let!(:notified_debt) { create(:debt, status: :notified) }

        it 'filters by status when provided' do
          get :index, params: { status: 'pending' }
          expect(assigns(:debts)).to include(pending_debt)
          expect(assigns(:debts)).not_to include(notified_debt)
        end

        it 'shows all debts when no status filter' do
          get :index
          expect(assigns(:debts)).to include(pending_debt, notified_debt)
        end
      end

      context 'with email search' do
        let!(:john_debt) { create(:debt, customer_email: 'john@test.com') }
        let!(:jane_debt) { create(:debt, customer_email: 'jane@test.com') }

        it 'searches by email when provided' do
          get :index, params: { search: 'john' }
          expect(assigns(:debts)).to include(john_debt)
          expect(assigns(:debts)).not_to include(jane_debt)
        end

        it 'shows all debts when no search term' do
          get :index
          expect(assigns(:debts)).to include(john_debt, jane_debt)
        end
      end
    end

    describe 'GET #show' do
      let(:debt) { create(:debt) }

      it 'returns successful response' do
        get :show, params: { id: debt.id }
        expect(response).to have_http_status(:success)
      end

      it 'assigns the requested debt' do
        get :show, params: { id: debt.id }
        expect(assigns(:debt)).to eq(debt)
      end

      it 'raises RecordNotFound for invalid id' do
        expect {
          get :show, params: { id: 'invalid' }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    describe 'GET #new' do
      it 'returns successful response' do
        get :new
        expect(response).to have_http_status(:success)
      end

      it 'assigns a new debt' do
        get :new
        expect(assigns(:debt)).to be_a_new(Debt)
      end
    end

    describe 'POST #create' do
      let(:valid_attributes) { attributes_for(:debt) }
      let(:invalid_attributes) { { amount: nil, due_date: nil, customer_email: nil } }

      context 'with valid parameters' do
        it 'creates a new debt via service' do
          expect(DebtCreationService).to receive(:call).and_return(create(:debt))
          
          post :create, params: { debt: valid_attributes }
        end

        it 'redirects to the debt show page' do
          debt = create(:debt)
          allow(DebtCreationService).to receive(:call).and_return(debt)
          
          post :create, params: { debt: valid_attributes }
          expect(response).to redirect_to(admin_debt_path(debt))
        end

        it 'sets success notice' do
          debt = create(:debt)
          allow(DebtCreationService).to receive(:call).and_return(debt)
          
          post :create, params: { debt: valid_attributes }
          expect(flash[:notice]).to eq('Debt was successfully created.')
        end
      end

      context 'with invalid parameters' do
        it 'does not create a debt' do
          invalid_debt = build(:debt, amount: nil)
          allow(DebtCreationService).to receive(:call)
            .and_raise(ActiveRecord::RecordInvalid.new(invalid_debt))

          expect {
            post :create, params: { debt: invalid_attributes }
          }.not_to change(Debt, :count)
        end

        it 'renders new template with unprocessable_entity status' do
          invalid_debt = build(:debt, amount: nil)
          allow(DebtCreationService).to receive(:call)
            .and_raise(ActiveRecord::RecordInvalid.new(invalid_debt))

          post :create, params: { debt: invalid_attributes }
          expect(response).to render_template(:new)
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'assigns the invalid debt record' do
          invalid_debt = build(:debt, amount: nil)
          allow(DebtCreationService).to receive(:call)
            .and_raise(ActiveRecord::RecordInvalid.new(invalid_debt))

          post :create, params: { debt: invalid_attributes }
          expect(assigns(:debt)).to eq(invalid_debt)
        end
      end
    end

    describe 'GET #edit' do
      let(:debt) { create(:debt) }

      it 'returns successful response' do
        get :edit, params: { id: debt.id }
        expect(response).to have_http_status(:success)
      end

      it 'assigns the requested debt' do
        get :edit, params: { id: debt.id }
        expect(assigns(:debt)).to eq(debt)
      end
    end

    describe 'PATCH #update' do
      let(:debt) { create(:debt) }
      let(:new_attributes) { { amount: 200, description: 'Updated description' } }
      let(:invalid_attributes) { { amount: -100 } }

      context 'with valid parameters' do
        it 'updates the debt' do
          patch :update, params: { id: debt.id, debt: new_attributes }
          debt.reload
          expect(debt.amount).to eq(200)
          expect(debt.description.to_plain_text.strip).to eq('Updated description')
        end

        it 'redirects to the debt show page' do
          patch :update, params: { id: debt.id, debt: new_attributes }
          expect(response).to redirect_to(admin_debt_path(debt))
        end

        it 'sets success notice' do
          patch :update, params: { id: debt.id, debt: new_attributes }
          expect(flash[:notice]).to eq('Debt was successfully updated.')
        end
      end

      context 'with invalid parameters' do
        it 'does not update the debt' do
          original_amount = debt.amount
          patch :update, params: { id: debt.id, debt: invalid_attributes }
          debt.reload
          expect(debt.amount).to eq(original_amount)
        end

        it 'renders edit template with unprocessable_entity status' do
          patch :update, params: { id: debt.id, debt: invalid_attributes }
          expect(response).to render_template(:edit)
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    describe 'DELETE #destroy' do
      let!(:debt) { create(:debt) }

      it 'destroys the debt' do
        expect {
          delete :destroy, params: { id: debt.id }
        }.to change(Debt, :count).by(-1)
      end

      it 'redirects to debts index' do
        delete :destroy, params: { id: debt.id }
        expect(response).to redirect_to(admin_debts_path)
      end

      it 'sets success notice' do
        delete :destroy, params: { id: debt.id }
        expect(flash[:notice]).to eq('Debt was successfully deleted.')
      end

      it 'raises error for non-existent debt' do
        expect {
          delete :destroy, params: { id: 'invalid' }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    describe 'before_action callbacks' do
      it 'sets debt for show, edit, update, destroy actions' do
        debt = create(:debt)
        
        get :show, params: { id: debt.id }
        expect(assigns(:debt)).to eq(debt)
        
        get :edit, params: { id: debt.id }
        expect(assigns(:debt)).to eq(debt)
      end
    end

    describe 'private methods' do
      describe '#debt_params' do
        it 'permits allowed parameters' do
          controller.params = ActionController::Parameters.new({
            debt: {
              amount: 100,
              due_date: Date.current,
              customer_email: 'test@test.com',
              description: 'Test description',
              status: 'pending',
              forbidden_param: 'should not be permitted'
            }
          })

          permitted_params = controller.send(:debt_params)
          expect(permitted_params).to include(:amount, :due_date, :customer_email, :description, :status)
          expect(permitted_params).not_to include(:forbidden_param)
        end
      end
    end
  end
end