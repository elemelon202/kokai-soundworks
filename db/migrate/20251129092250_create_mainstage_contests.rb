class CreateMainstageContests < ActiveRecord::Migration[7.1]
  def change
    create_table :mainstage_contests do |t|
      t.date :start_date, null: false
      t.date :end_date, null: false
      t.string :status, default: 'active'

      t.timestamps
    end

    add_index :mainstage_contests, :status
    add_index :mainstage_contests, [:start_date, :end_date]
  end
end
