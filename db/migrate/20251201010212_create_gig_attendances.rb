class CreateGigAttendances < ActiveRecord::Migration[7.1]
  def change
    create_table :gig_attendances do |t|
      t.references :gig, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :status, default: 0

      t.timestamps
    end

    add_index :gig_attendances, [:gig_id, :user_id], unique: true
  end
end
