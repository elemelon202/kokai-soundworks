class CreateInvolvements < ActiveRecord::Migration[7.1]
  def change
    create_table :involvements do |t|
      t.references :band, null: false, foreign_key: true
      t.references :musician, null: false, foreign_key: true

      t.timestamps
    end
  end
end
