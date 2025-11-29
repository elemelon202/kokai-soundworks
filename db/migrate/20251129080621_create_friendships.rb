class CreateFriendships < ActiveRecord::Migration[7.1]
    def change
      create_table :friendships do |t|
        t.bigint :requester_id, null: false
        t.bigint :addressee_id, null: false
        t.string :status, null: false, default: 'pending'

        t.timestamps
      end

      add_index :friendships, :requester_id
      add_index :friendships, :addressee_id
      add_index :friendships, [:requester_id, :addressee_id], unique: true
      add_index :friendships, :status
      add_foreign_key :friendships, :users, column: :requester_id
      add_foreign_key :friendships, :users, column: :addressee_id
    end
end
