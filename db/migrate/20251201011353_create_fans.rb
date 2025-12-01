class CreateFans < ActiveRecord::Migration[7.1]
  def change
    create_table :fans do |t|
      t.references :user, null: false, foreign_key: true
      t.string :display_name
      t.text :bio
      t.string :location

      t.timestamps
    end
  end
end
