FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123" }
    password_confirmation { "password123" }
    confirmed_at { Time.current }
    role { :customer }

    trait :admin do
      role { :admin }
      sequence(:email) { |n| "admin#{n}@dluzirna.cz" }
    end

    trait :customer do
      role { :customer }
      sequence(:email) { |n| "customer#{n}@example.com" }
    end

    trait :unconfirmed do
      confirmed_at { nil }
    end
  end
end
