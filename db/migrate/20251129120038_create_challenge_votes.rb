class CreateChallengeVotes < ActiveRecord::Migration[7.1]
  def change
    create_table :challenge_votes do |t|
      t.references :user, null: false, foreign_key: true
      t.references :challenge_response, null: false, foreign_key: true

      t.timestamps
    end

    # One vote per user per response
    add_index :challenge_votes, [:user_id, :challenge_response_id], unique: true
  end
end
