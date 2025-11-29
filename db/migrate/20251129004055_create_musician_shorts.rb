class CreateMusicianShorts < ActiveRecord::Migration[7.1]
  def change
    create_table :musician_shorts do |t|
      t.references :musician, null: false, foreign_key: true
      t.string :title
      t.text :description
      t.integer :position

      t.timestamps
    end
  end
end
