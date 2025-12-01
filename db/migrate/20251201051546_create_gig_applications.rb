class CreateGigApplications < ActiveRecord::Migration[7.1]
  def change
    create_table :gig_applications do |t|
      t.references :gig, null: false, foreign_key: true
      t.references :band, null: false, foreign_key: true
      t.integer :status, default: 0
      t.text :message
      t.text :response_message

      t.timestamps
    end

    add_index :gig_applications, [:gig_id, :band_id], unique: true
  end
end
