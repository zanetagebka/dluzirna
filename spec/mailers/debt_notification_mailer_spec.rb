require "rails_helper"

RSpec.describe DebtNotificationMailer, type: :mailer do
  describe "debt_notification" do
    let(:debt) do
      create(:debt,
        customer_email: "customer@example.com",
        amount: 15000.50,
        due_date: Date.current + 30.days,
        description: "Faktura č. 2024001 za stavební materiál"
      )
    end
    let(:mail) { DebtNotificationMailer.debt_notification(debt) }

    describe "email headers" do
      it "sets correct recipient" do
        expect(mail.to).to eq(["customer@example.com"])
      end

      it "sets correct sender" do
        expect(mail.from).to eq(["noreply@dluzirna.cz"])
      end

      it "sets bilingual subject" do
        expect(mail.subject).to eq("Oznámení o dlužné částce / Debt notification")
      end

      it "sets content type to multipart" do
        expect(mail.content_type).to match(/multipart/)
      end
    end

    describe "email content" do
      it "includes debt URL with token in body" do
        expect(mail.body.encoded).to include("pohledavky/")
      end

      it "includes debt amount formatted with currency" do
        expect(mail.body.encoded).to include("15,000.50")
      end

      it "includes due date" do
        expect(mail.body.encoded).to include("2025")
      end

      it "includes debt description" do
        expect(mail.body.encoded).to include("2024001")
      end

      it "includes secure debt URL with token" do
        expect(mail.body.encoded).to include(pohledavky_url(debt.token))
      end

      it "does not expose internal debt ID" do
        expect(mail.body.encoded).not_to include(debt.id.to_s)
      end
    end

    describe "security and privacy" do
      it "uses secure token in URL, not database ID" do
        expect(mail.body.encoded).to match(/pohledavky\/[A-Za-z0-9_-]+/)
        expect(mail.body.encoded).not_to match(/pohledavky\/\d+/)
      end

      it "includes privacy notice" do
        expect(mail.body.encoded).to include("soukrom")
      end
    end

    describe "email deliverability" do
      it "creates deliverable email object" do
        expect(mail.message).to be_a(Mail::Message)
        expect(mail.from).to be_present
        expect(mail.to).to be_present
      end

      it "passes spam filter checks" do
        # Basic anti-spam requirements
        expect(mail.subject.length).to be > 10
        expect(mail.body.encoded.length).to be > 100
        expect(mail.from).to be_present
        expect(mail.to).to be_present
      end
    end
  end

  describe "error handling" do
    context "with invalid debt data" do
      it "handles missing customer email gracefully" do
        debt = build(:debt, customer_email: nil)
        expect { DebtNotificationMailer.debt_notification(debt) }.not_to raise_error
      end

    end

    context "with special characters in data" do
      it "properly escapes HTML content" do
        debt = create(:debt,
          customer_email: "test@example.com",
          description: "Description with <b>HTML</b> & special chars"
        )
        mail = DebtNotificationMailer.debt_notification(debt)
        
        expect(mail.body.encoded).to include("&amp;")
        expect(mail.body.encoded).to include("special chars")
      end
    end
  end
end
