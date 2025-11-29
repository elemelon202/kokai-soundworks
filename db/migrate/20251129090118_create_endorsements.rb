class CreateEndorsements < ActiveRecord::Migration[7.1]
  def change
    create_table :endorsements do |t|
      t.references :user, null: false, foreign_key: true
      t.references :musician, null: false, foreign_key: true
      t.string :skill, null: false

      t.timestamps
    end

    # Each user can only endorse a musician once per skill
    add_index :endorsements, [:user_id, :musician_id, :skill], unique: true
  end
end
