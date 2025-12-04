class CreateFundedGigs < ActiveRecord::Migration[7.1]
  def change
    create_table :funded_gigs do |t|
      t.references :gig, null: false, foreign_key: true, index: { unique: true }
      t.integer :funding_target_cents, null: false
      t.string :currency, default: 'jpy'
      t.integer :current_pledged_cents, default: 0
      t.integer :funding_status, default: 0  # enum
      t.date :funding_deadline
      t.integer :deadline_days_before, default: 7
      t.boolean :allow_partial_funding, default: false
      t.integer :minimum_funding_percent, default: 80
      t.text :venue_message
      t.integer :max_bands, default: 3
      t.datetime :applications_open_at
      t.datetime :applications_close_at
      t.datetime :pledging_opens_at
      t.datetime :funded_at
      t.datetime :failed_at

      t.timestamps
    end

    add_index :funded_gigs, :funding_status
    add_index :funded_gigs, :funding_deadline
  end
end
