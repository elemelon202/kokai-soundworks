class CreateBandMainstageWinners < ActiveRecord::Migration[7.1]
  def change
    create_table :band_mainstage_winners do |t|
      t.references :band, null: false, foreign_key: true
      t.references :band_mainstage_contest, null: false, foreign_key: true, index: false
      t.integer :final_score, default: 0
      t.integer :engagement_score, default: 0
      t.integer :vote_score, default: 0

      t.timestamps
    end

    # One winner per contest
    add_index :band_mainstage_winners, :band_mainstage_contest_id, unique: true, name: 'idx_band_mainstage_winners_contest'
  end
end
