class CreateFundedGigTickets < ActiveRecord::Migration[7.1]
  def change
    create_table :funded_gig_tickets do |t|
      t.references :funded_gig, null: false, foreign_key: true
      t.references :pledge, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :ticket_code, null: false
      t.integer :status, default: 0  # enum: valid, checked_in, cancelled
      t.datetime :checked_in_at

      t.timestamps
    end

    add_index :funded_gig_tickets, :ticket_code, unique: true
    add_index :funded_gig_tickets, [:funded_gig_id, :user_id]
  end
end
