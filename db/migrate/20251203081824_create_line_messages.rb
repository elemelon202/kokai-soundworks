class CreateLineMessages < ActiveRecord::Migration[7.1]
  def change
    create_table :line_messages do |t|
      t.string :line_group_id, null: false
      t.string :line_user_id
      t.string :display_name
      t.text :content, null: false
      t.string :message_id
      t.datetime :sent_at, null: false

      t.timestamps
    end

    add_index :line_messages, :line_group_id
    add_index :line_messages, [:line_group_id, :sent_at]
    add_index :line_messages, :message_id, unique: true
  end
end
