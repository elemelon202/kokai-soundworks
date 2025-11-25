class CreateVenues < ActiveRecord::Migration[7.1]
  def change
    create_table :venues do |t|
      t.string :name
      t.string :address
      t.string :city
      t.integer :capacity
      t.text :description
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
