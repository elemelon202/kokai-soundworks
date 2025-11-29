class CreateShoutouts < ActiveRecord::Migration[7.1]
  def change
    create_table :shoutouts do |t|
      t.references :user, null: false, foreign_key: true
      t.references :musician, null: false, foreign_key: true
      t.text :content

      t.timestamps
    end
  end
end
