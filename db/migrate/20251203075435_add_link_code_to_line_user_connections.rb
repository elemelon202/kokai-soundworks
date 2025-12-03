class AddLinkCodeToLineUserConnections < ActiveRecord::Migration[7.1]
  def change
    add_column :line_user_connections, :link_code, :string
    add_index :line_user_connections, :link_code, unique: true
  end
end
