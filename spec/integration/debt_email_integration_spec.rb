require "rails_helper"

RSpec.describe "Debt Email Integration", type: :request do
  let(:admin_user) { create(:user, :admin) }

  before do
    sign_in admin_user, scope: :user
    ActionMailer::Base.deliveries.clear
  end

  describe "POST /admin/debts" do
    context "creating a new debt" do
      let(:debt_params) do
        {
          debt: {
            customer_email: "jan.novak@example.com",
            amount: 25000,
            due_date: Date.current + 30.days,
            description: "Faktura za stavební materiál"
          }
        }
      end

      it "sends debt notification email" do
        expect {
          post admin_debts_path, params: debt_params
        }.to change { ActionMailer::Base.deliveries.count }.by(1)
      end

      it "sends email to correct recipient" do
        post admin_debts_path, params: debt_params

        email = ActionMailer::Base.deliveries.last
        expect(email.to).to include("jan.novak@example.com")
      end

      it "includes debt information in email" do
        post admin_debts_path, params: debt_params

        email = ActionMailer::Base.deliveries.last
        debt = Debt.last

        expect(email.body.encoded).to include("Dear customer")
        expect(email.body.encoded).to include("25,000.00")
        expect(email.body.encoded).to include("Faktura za stavebn")
        expect(email.body.encoded).to include("/pohledavky/#{debt.token}")
      end

      it "creates debt record with correct status" do
        post admin_debts_path, params: debt_params

        debt = Debt.last
        expect(debt.status).to eq("notified")
      end

      it "handles email delivery failures gracefully" do
        # Simulate email delivery failure
        allow(DebtNotificationMailer).to receive_message_chain(:delay, :debt_notification).and_raise(StandardError.new("SMTP Error"))

        expect {
          post admin_debts_path, params: debt_params
        }.not_to raise_error

        # Should still create debt even if email fails
        expect(Debt.count).to eq(1)
      end
    end

    context "with invalid email address" do
      let(:invalid_debt_params) do
        {
          debt: {
            customer_email: "invalid-email",
            amount: 1000,
            due_date: Date.current + 30.days,
            description: "Test debt"
          }
        }
      end

      it "does not send email with invalid recipient" do
        expect {
          post admin_debts_path, params: invalid_debt_params
        }.not_to change { ActionMailer::Base.deliveries.count }
      end

      it "shows validation error" do
        post admin_debts_path, params: invalid_debt_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "PATCH /admin/debts/:id" do
    let(:debt) { create(:debt) }

    context "when updating debt amount" do
      let(:update_params) do
        {
          debt: {
            amount: debt.amount + 5000,
            send_notification: "1"
          }
        }
      end

      it "sends updated notification email" do
        expect {
          patch admin_debt_path(debt), params: update_params
        }.to change { ActionMailer::Base.deliveries.count }.by(1)
      end

      it "includes updated amount in email" do
        patch admin_debt_path(debt), params: update_params

        email = ActionMailer::Base.deliveries.last
        updated_amount = debt.amount + 5000
        # Check that the updated amount appears in the email (Czech format with space separator)
        formatted_amount = ActionController::Base.helpers.number_with_delimiter(updated_amount, delimiter: ' ').gsub('.', ',')
        expect(email.body.encoded).to include(formatted_amount)
      end
    end

    context "when updating without notification flag" do
      let(:update_params) do
        {
          debt: {
            amount: debt.amount + 5000
          }
        }
      end

      it "does not send notification email" do
        expect {
          patch admin_debt_path(debt), params: update_params
        }.not_to change { ActionMailer::Base.deliveries.count }
      end
    end
  end
end
