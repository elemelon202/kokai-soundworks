class AddForeignKeyToBandInvitationsInviter < ActiveRecord::Migration[7.1]
  def change
    # Change inviter_id from integer to bigint to match users.id type
    change_column :band_invitations, :inviter_id, :bigint

    # Add foreign key constraint
    add_foreign_key :band_invitations, :users, column: :inviter_id

    # Add index for faster lookups
    add_index :band_invitations, :inviter_id
  end
end
