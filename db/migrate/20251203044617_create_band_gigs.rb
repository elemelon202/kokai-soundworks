class CreateBandGigs < ActiveRecord::Migration[7.1]
  def change
    create_table :band_gigs do |t|
      t.references :band, null: false, foreign_key: true
      t.string :name
      t.string :venue_name
      t.date :date
      t.string :location
      t.text :notes

      t.timestamps
    end
  end
end
