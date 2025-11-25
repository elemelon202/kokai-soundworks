class CreateBookings < ActiveRecord::Migration[7.1]
  def change
    create_table :bookings do |t|
      t.text :message
      t.text :status
      t.references :band, null: false, foreign_key: true
      t.references :gig, null: false, foreign_key: true

      t.timestamps
    end
  end
end
