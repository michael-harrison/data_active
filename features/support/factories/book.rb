FactoryGirl.define do
  factory :book do
    sequence(:id) { |n| n }
    sequence(:name) { |n| "Book #{n}" }
  end
end
