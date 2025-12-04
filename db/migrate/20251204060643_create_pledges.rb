class CreatePledges < ActiveRecord::Migration[7.1]
  def change
    create_table :pledges do |t|
      t.references :funded_gig, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :amount_cents, null: false
      t.string :currency, default: 'jpy'
      t.integer :status, default: 0  # enum: pending, authorized, captured, refunded, failed
      t.string :stripe_payment_intent_id
      t.string :stripe_payment_method_id
      t.datetime :authorized_at
      t.datetime :captured_at
      t.datetime :refunded_at
      t.string :refund_reason
      t.text :fan_message
      t.boolean :anonymous, default: false

      t.timestamps
    end

    add_index :pledges, :stripe_payment_intent_id, unique: true
    add_index :pledges, [:funded_gig_id, :user_id], unique: true
    add_index :pledges, :status
  end
end
