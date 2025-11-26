class CreateBandInvitations < ActiveRecord::Migration[7.1]
  def change
    create_table :band_invitations do |t|
      t.references :band, null: false, foreign_key: true
      t.references :musician, null: false, foreign_key: true
      t.integer :inviter_id
      t.string :status
      t.string :token

      t.timestamps
    end
  end
end
