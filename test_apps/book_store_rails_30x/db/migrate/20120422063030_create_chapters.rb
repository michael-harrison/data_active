class CreateChapters < ActiveRecord::Migration
  def self.up
    create_table :chapters do |t|
      t.string :title
      t.string :introduction
      t.references :book

      t.timestamps
    end
  end

  def self.down
    drop_table :chapters
  end
end
