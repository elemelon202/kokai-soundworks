class CreateMainstageVotes < ActiveRecord::Migration[7.1]
  def change
    create_table :mainstage_votes do |t|
      t.references :user, null: false, foreign_key: true
      t.references :musician, null: false, foreign_key: true
      t.references :mainstage_contest, null: false, foreign_key: true

      t.timestamps
    end

    # One vote per user per contest
    add_index :mainstage_votes, [:user_id, :mainstage_contest_id], unique: true
  end
end
