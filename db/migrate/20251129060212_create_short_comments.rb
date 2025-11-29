class CreateShortComments < ActiveRecord::Migration[7.1]
  def change
    create_table :short_comments do |t|
      t.references :musician_short, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.text :body

      t.timestamps
    end
  end
end
