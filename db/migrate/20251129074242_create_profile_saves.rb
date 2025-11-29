  class CreateProfileSaves < ActiveRecord::Migration[7.1]
    def change
      create_table :profile_saves do |t|
        t.bigint :user_id, null: false
        t.string :saveable_type, null: false
        t.bigint :saveable_id, null: false

        t.timestamps
      end

      add_index :profile_saves, :user_id
      add_index :profile_saves, [:saveable_type, :saveable_id]
      add_index :profile_saves, [:user_id, :saveable_type, :saveable_id], unique: true, name: 'index_profile_saves_uniqueness'
      add_foreign_key :profile_saves, :users
    end
  end
