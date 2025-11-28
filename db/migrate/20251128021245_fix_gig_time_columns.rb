class FixGigTimeColumns < ActiveRecord::Migration[7.1]
  def up
    # Change start_time and end_time from date to time type
    # This allows storing actual times like "19:00" instead of dates
    # Since date can't be cast directly to time, we drop and recreate with default values
    remove_column :gigs, :start_time
    remove_column :gigs, :end_time
    add_column :gigs, :start_time, :time
    add_column :gigs, :end_time, :time
  end

  def down
    remove_column :gigs, :start_time
    remove_column :gigs, :end_time
    add_column :gigs, :start_time, :date
    add_column :gigs, :end_time, :date
  end
end
