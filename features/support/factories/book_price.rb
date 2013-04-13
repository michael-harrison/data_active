FactoryGirl.define do
  factory :book_price do
    sequence(:id) { |n| n }
    sequence(:sell) { |n| n * 50.0 }
    sequence(:educational) { |n| n * 35.0 }
    sequence(:cost) { |n| n * 20.0 }
  end
end
