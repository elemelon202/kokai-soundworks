class CreateBandMainstageContests < ActiveRecord::Migration[7.1]
  def change
    create_table :band_mainstage_contests do |t|
      t.date :start_date, null: false
      t.date :end_date, null: false
      t.string :status, default: 'active'

      t.timestamps
    end

    add_index :band_mainstage_contests, :status
    add_index :band_mainstage_contests, [:start_date, :end_date]
  end
end
