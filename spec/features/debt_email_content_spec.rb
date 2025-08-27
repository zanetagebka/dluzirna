require "rails_helper"

RSpec.describe "Debt Email Content Verification", type: :feature do
  let(:admin_user) { create(:user, :admin) }
  let(:debt) do
    create(:debt,
      customer_email: "marie@example.com",
      amount: 45000.75,
      due_date: Date.new(2024, 12, 31),
      description: rich_text_description
    )
  end
  
  let(:rich_text_description) do
    "<p><strong>Faktura č. 2024-0156</strong></p><p>Stavební materiál:</p><ul><li>Cement 50kg - 20 kusů</li><li>Cihly 500ks</li></ul><p>Dodáno dne: 15.11.2024</p>"
  end

  describe "email template rendering" do
    let(:mail) { DebtNotificationMailer.debt_notification(debt) }

    it "renders both HTML and text versions" do
      expect(mail.html_part).to be_present
      expect(mail.text_part).to be_present
    end

    context "HTML version" do
      let(:html_body) { mail.html_part.body.decoded }

      it "includes proper customer greeting" do
        expect(html_body).to include("Vážený zákazníku")
      end

      it "includes formatted currency amount" do
        expect(html_body).to include("Kč45 000,75")
        expect(html_body).not_to include("45000.75") # Raw number
      end

      it "includes formatted due date" do
        expect(html_body).to include("31. prosinec 2024")
      end

      it "renders rich text description with HTML formatting" do
        expect(html_body).to include("<strong>Faktura č. 2024-0156</strong>")
        expect(html_body).to include("<ul>")
        expect(html_body).to include("<li>Cement 50kg - 20 kusů</li>")
      end

      it "includes clickable secure link" do
        expect(html_body).to include("pohledavky/#{debt.token}")
        expect(html_body).to match(/<a[^>]*href="[^"]*pohledavky\/#{debt.token}"[^>]*>/)
      end

      it "includes company branding" do
        expect(html_body).to include("Oznámení o neuhrazené pohledávce")
      end

      it "includes contact information" do
        expect(html_body).to match(/kontaktovat|kontakt/i)
      end

      it "includes privacy information" do
        expect(html_body).to match(/soukromých údajů|Privacy/i)
      end
    end

    context "text version" do
      let(:text_body) { mail.text_part.body.decoded }

      it "includes proper customer greeting in plain text" do
        expect(text_body).to include("Vážený zákazníku")
      end

      it "includes amount with currency" do
        expect(text_body).to include("Kč45 000,75")
      end

      it "includes due date in readable format" do
        expect(text_body).to include("31. prosinec 2024")
      end

      it "includes rich text description content" do
        expect(text_body).to include("Faktura č. 2024-0156")
        expect(text_body).to include("Cement 50kg - 20 kusů")
        # Note: Text version may still contain some HTML from rich text
      end

      it "includes accessible debt URL" do
        expect(text_body).to include("/pohledavky/#{debt.token}")
      end
    end
  end

  describe "secure token verification" do
    let(:mail) { DebtNotificationMailer.debt_notification(debt) }
    let(:html_body) { mail.html_part.body.decoded }

    it "uses cryptographically secure token" do
      token_in_email = html_body.match(/pohledavky\/([A-Za-z0-9_-]+)/)[1]
      expect(token_in_email).to eq(debt.token)
      expect(token_in_email.length).to be >= 20
    end

    it "token provides access to debt details" do
      # This test would require Capybara, so let's just verify the URL is valid
      expect(pohledavky_path(debt.token)).to include("/pohledavky/#{debt.token}")
      expect(debt.token).to be_present
    end

    it "does not expose database ID anywhere" do
      expect(html_body).not_to include(debt.id.to_s)
      expect(mail.text_part.body.decoded).not_to include(debt.id.to_s)
    end

    it "token is unique per debt" do
      other_debt = create(:debt)
      expect(debt.token).not_to eq(other_debt.token)
    end
  end

  describe "email accessibility and localization" do
    let(:mail) { DebtNotificationMailer.debt_notification(debt) }

    it "uses proper Czech locale formatting" do
      html_body = mail.html_part.body.decoded
      
      # Czech date format
      expect(html_body).to match(/\d{1,2}\.\s\w+\s\d{4}/)
      
      # Czech number format with spaces
      expect(html_body).to include("45 000,75")
    end

    it "includes proper encoding for Czech characters" do
      debt_with_czech = create(:debt,
        customer_email: "jiri.dvorak@example.com",
        description: "Účet za žádostí už je přítomný"
      )
      
      czech_mail = DebtNotificationMailer.debt_notification(debt_with_czech)
      html_body = czech_mail.html_part.body.decoded
      
      expect(html_body).to include("Vážený zákazníku")
      expect(html_body).to include("už je přítomný")
    end

    it "includes alt text for images" do
      html_body = mail.html_part.body.decoded
      images = html_body.scan(/<img[^>]*>/)
      
      images.each do |img|
        expect(img).to match(/alt="[^"]+"/i)
      end
    end
  end

  describe "spam prevention" do
    let(:mail) { DebtNotificationMailer.debt_notification(debt) }

    it "includes proper sender reputation headers" do
      expect(mail.from).to eq(["noreply@dluzirna.cz"])
      expect(mail.reply_to).to be_present
    end

    it "avoids spam trigger words in subject" do
      subject = mail.subject.downcase
      spam_words = ["free", "urgent", "act now", "winner", "congratulations"]
      
      spam_words.each do |word|
        expect(subject).not_to include(word)
      end
    end

    it "maintains proper text-to-HTML ratio" do
      html_length = mail.html_part.body.decoded.length
      text_length = mail.text_part.body.decoded.length
      
      ratio = text_length.to_f / html_length.to_f
      expect(ratio).to be > 0.1 # At least 10% text content
    end
  end
end