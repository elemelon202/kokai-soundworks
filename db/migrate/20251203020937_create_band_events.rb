class CreateBandEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :band_events do |t|
      t.references :band, null: false, foreign_key: true
      t.string :title
      t.integer :event_type
      t.date :date
      t.time :start_time
      t.time :end_time
      t.string :location
      t.text :description

      t.timestamps
    end
  end
end
