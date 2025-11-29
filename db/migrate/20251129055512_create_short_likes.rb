class CreateShortLikes < ActiveRecord::Migration[7.1]
  def change
    create_table :short_likes do |t|
      t.references :musician_short, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    # Ensure a user can only like a short once
    add_index :short_likes, [:musician_short_id, :user_id], unique: true
  end
end
