class CreateMemberAvailabilities < ActiveRecord::Migration[7.1]
  def change
    create_table :member_availabilities do |t|
      t.references :musician, null: false, foreign_key: true
      t.references :band, null: false, foreign_key: true
      t.date :date
      t.integer :status
      t.string :reason

      t.timestamps
    end
  end
end
