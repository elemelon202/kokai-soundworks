class CreateLinePendingEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :line_pending_events do |t|
      t.references :line_band_connection, null: false, foreign_key: true
      t.references :suggested_by, foreign_key: { to_table: :users }
      t.string :line_message_id
      t.string :event_type
      t.string :title
      t.date :date
      t.time :start_time
      t.time :end_time
      t.string :location
      t.text :raw_message
      t.json :ai_response
      t.string :status, default: 'pending'

      t.timestamps
    end
  end
end
