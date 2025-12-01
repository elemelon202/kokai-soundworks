class AddGigToGigApplications < ActiveRecord::Migration[7.1]
  def change
    add_reference :gig_applications, :gig, null: false, foreign_key: true
    add_index :gig_applications, [:gig_id, :band_id], unique: true
    change_column_default :gig_applications, :status, 0
  end
end
