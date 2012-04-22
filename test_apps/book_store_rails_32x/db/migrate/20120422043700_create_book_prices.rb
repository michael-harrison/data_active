class CreateBookPrices < ActiveRecord::Migration
  def change
    create_table :book_prices do |t|
      t.float :sell
      t.float :educational
      t.float :cost
      t.references :book

      t.timestamps
    end
  end
end
