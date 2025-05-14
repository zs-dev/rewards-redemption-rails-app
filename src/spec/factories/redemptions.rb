FactoryBot.define do
  factory :redemption do
    association :user
    association :reward
  end
end