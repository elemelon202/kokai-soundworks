class CreateBandMainstageVotes < ActiveRecord::Migration[7.1]
  def change
    create_table :band_mainstage_votes do |t|
      t.references :user, null: false, foreign_key: true
      t.references :band, null: false, foreign_key: true
      t.references :band_mainstage_contest, null: false, foreign_key: true

      t.timestamps
    end

    # One vote per user per contest
    add_index :band_mainstage_votes, [:user_id, :band_mainstage_contest_id], unique: true, name: 'idx_band_mainstage_votes_user_contest'
  end
end
