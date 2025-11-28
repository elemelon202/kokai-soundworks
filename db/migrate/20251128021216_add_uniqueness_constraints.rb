class AddUniquenessConstraints < ActiveRecord::Migration[7.1]
  def up
    # Remove duplicate message_reads before adding unique constraint
    execute <<-SQL
      DELETE FROM message_reads
      WHERE id NOT IN (
        SELECT MIN(id)
        FROM message_reads
        GROUP BY message_id, user_id
      )
    SQL

    # Remove duplicate participations before adding unique constraint
    execute <<-SQL
      DELETE FROM participations
      WHERE id NOT IN (
        SELECT MIN(id)
        FROM participations
        GROUP BY user_id, chat_id
      )
    SQL

    # Remove duplicate involvements before adding unique constraint
    execute <<-SQL
      DELETE FROM involvements
      WHERE id NOT IN (
        SELECT MIN(id)
        FROM involvements
        GROUP BY band_id, musician_id
      )
    SQL

    # Add unique index to prevent duplicate band memberships
    add_index :involvements, [:band_id, :musician_id], unique: true, name: 'index_involvements_on_band_and_musician_unique'

    # Add unique index to prevent duplicate message reads
    add_index :message_reads, [:message_id, :user_id], unique: true, name: 'index_message_reads_on_message_and_user_unique'

    # Add unique index to prevent duplicate chat participations
    add_index :participations, [:user_id, :chat_id], unique: true, name: 'index_participations_on_user_and_chat_unique'
  end

  def down
    remove_index :involvements, name: 'index_involvements_on_band_and_musician_unique'
    remove_index :message_reads, name: 'index_message_reads_on_message_and_user_unique'
    remove_index :participations, name: 'index_participations_on_user_and_chat_unique'
  end
end
