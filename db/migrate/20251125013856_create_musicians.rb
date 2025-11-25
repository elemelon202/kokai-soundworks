class CreateMusicians < ActiveRecord::Migration[7.1]
  def change
    create_table :musicians do |t|
      t.string :name
      t.string :instrument
      t.integer :age
      t.string :styles
      t.string :location
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
