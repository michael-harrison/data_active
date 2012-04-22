class CreateBookPrices < ActiveRecord::Migration
  def self.up
    create_table :book_prices do |t|
      t.float :sell
      t.float :educational
      t.float :cost
      t.references :book

      t.timestamps
    end
  end

  def self.down
    drop_table :book_prices
  end
end
