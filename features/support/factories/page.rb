FactoryGirl.define do
  factory :page do
    sequence(:id) { |n| n }
    sequence(:number) { |n| "Chapter #{n}" }
    sequence(:content) { |n| 1.upto(n).each { 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.' }.join(' ') }
  end
end
