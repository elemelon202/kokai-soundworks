class CreateChallenges < ActiveRecord::Migration[7.1]
  def change
    create_table :challenges do |t|
      t.bigint :creator_id, null: false
      t.bigint :original_short_id, null: false
      t.string :title, null: false
      t.text :description
      t.string :status, default: 'open', null: false
      t.bigint :winner_id
      t.integer :responses_count, default: 0

      t.timestamps
    end

    add_index :challenges, :creator_id
    add_index :challenges, :original_short_id
    add_index :challenges, :status
    add_foreign_key :challenges, :musicians, column: :creator_id
    add_foreign_key :challenges, :musician_shorts, column: :original_short_id
  end
end
