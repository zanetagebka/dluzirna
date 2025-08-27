FactoryBot.define do
  factory :debt do
    amount { rand(1000.0..50000.0).round(2) }
    due_date { rand(30.days.ago..30.days.from_now) }
    sequence(:customer_email) { |n| "debtor#{n}@example.com" }
    description { Faker::Lorem.paragraph(sentence_count: rand(2..5)) }
    token { SecureRandom.urlsafe_base64(32) }
    status { :pending }
    customer_user { nil }

    trait :with_customer do
      association :customer_user, factory: :user
    end

    trait :overdue do
      due_date { rand(30.days.ago..1.day.ago) }
    end

    trait :pending do
      status { :pending }
    end

    trait :notified do
      status { :notified }
      notified_at { rand(1.day.ago..Time.current) }
    end

    trait :viewed do
      status { :viewed }
      viewed_at { rand(1.day.ago..Time.current) }
    end

    trait :registered do
      status { :registered }
      with_customer
    end

    trait :resolved do
      status { :resolved }
    end
  end
end