FactoryGirl.define do
  factory :chapter do
    sequence(:id) { |n| n }
    sequence(:title) { |n| "Chapter #{n}" }
    sequence(:introduction) { |n| 1.upto(n).each { 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.' }.join(' ') }
  end
end
