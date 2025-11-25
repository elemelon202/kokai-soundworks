class CreateGigs < ActiveRecord::Migration[7.1]
  def change
    create_table :gigs do |t|
      t.string :name
      t.date :date
      t.date :start_time
      t.date :end_time
      t.text :status

      t.timestamps
    end
  end
end
