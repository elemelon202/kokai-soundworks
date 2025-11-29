class CreateChallengeResponses < ActiveRecord::Migration[7.1]
  def change
    create_table :challenge_responses do |t|
      t.references :challenge, null: false, foreign_key: true
      t.references :musician_short, null: false, foreign_key: true
      t.references :musician, null: false, foreign_key: true
      t.integer :votes_count, default: 0

      t.timestamps
    end

    # Ensure one response per musician per challenge
    add_index :challenge_responses, [:challenge_id, :musician_id], unique: true
  end
end
