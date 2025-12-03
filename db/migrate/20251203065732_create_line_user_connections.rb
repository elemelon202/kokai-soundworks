class CreateLineUserConnections < ActiveRecord::Migration[7.1]
  def change
    create_table :line_user_connections do |t|
      t.references :user, null: false, foreign_key: true
      t.string :line_user_id, null: false
      t.string :line_display_name
      t.string :connection_token
      t.datetime :connected_at

      t.timestamps
    end

    add_index :line_user_connections, :line_user_id, unique: true
    add_index :line_user_connections, :connection_token, unique: true
  end
end
