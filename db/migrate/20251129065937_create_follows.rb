class CreateFollows < ActiveRecord::Migration[7.1]
  def change
    create_table :follows do |t|
      t.bigint :follower_id, null: false
      t.string :followable_type, null: false
      t.bigint :followable_id, null: false

      t.timestamps
    end

    add_index :follows, :follower_id
    add_index :follows, [:followable_type, :followable_id]
    add_index :follows, [:follower_id, :followable_type, :followable_id], unique: true, name: 'index_follows_on_uniqueness'
    add_foreign_key :follows, :users, column: :follower_id
  end
end
