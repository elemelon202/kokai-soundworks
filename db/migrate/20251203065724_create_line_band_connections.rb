class CreateLineBandConnections < ActiveRecord::Migration[7.1]
  def change
    create_table :line_band_connections do |t|
      t.references :band, null: false, foreign_key: true
      t.string :line_group_id, null: false
      t.string :line_group_name
      t.boolean :active, default: true
      t.boolean :auto_create_events, default: false

      t.timestamps
    end

    add_index :line_band_connections, :line_group_id, unique: true
  end
end
