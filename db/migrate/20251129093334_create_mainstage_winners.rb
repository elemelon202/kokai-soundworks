class CreateMainstageWinners < ActiveRecord::Migration[7.1]
  def change
    create_table :mainstage_winners do |t|
      t.references :musician, null: false, foreign_key: true
      # index: false because we add unique index below
      t.references :mainstage_contest, null: false, foreign_key: true, index: false
      t.integer :final_score, default: 0
      t.integer :engagement_score, default: 0
      t.integer :vote_score, default: 0

      t.timestamps
    end

    # One winner per contest
    add_index :mainstage_winners, :mainstage_contest_id, unique: true
  end
end
