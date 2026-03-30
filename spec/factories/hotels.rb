FactoryBot.define do
  factory :hotel do
    sequence(:name) { |n| "Hotel #{n}" }
    timezone { "UTC" }
  end
end
