class FixGigsTable < ActiveRecord::Migration[7.0]
  def change
    add_reference :gigs, :venue, null: false, foreign_key: true

    # Change start_time and end_time from date to tim
  end
end
