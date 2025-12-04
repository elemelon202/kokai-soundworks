class CreateVenueStripeAccounts < ActiveRecord::Migration[7.1]
  def change
    create_table :venue_stripe_accounts do |t|
      t.references :venue, null: false, foreign_key: true, index: { unique: true }
      t.string :stripe_account_id, null: false
      t.string :account_status, default: 'pending'
      t.boolean :charges_enabled, default: false
      t.boolean :payouts_enabled, default: false
      t.json :requirements
      t.datetime :onboarded_at

      t.timestamps
    end
    add_index :venue_stripe_accounts, :stripe_account_id, unique: true
  end
end
