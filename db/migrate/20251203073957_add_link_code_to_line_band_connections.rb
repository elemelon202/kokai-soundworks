class AddLinkCodeToLineBandConnections < ActiveRecord::Migration[7.1]
  def change
    add_column :line_band_connections, :link_code, :string
    add_index :line_band_connections, :link_code, unique: true
    add_column :line_band_connections, :linked_at, :datetime
    add_reference :line_band_connections, :linked_by, foreign_key: { to_table: :users }
  end
end
