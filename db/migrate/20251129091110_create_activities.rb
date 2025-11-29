class CreateActivities < ActiveRecord::Migration[7.1]
  def change
    create_table :activities do |t|
      t.references :user, null: false, foreign_key: true
      t.references :trackable, polymorphic: true, null: false
      t.references :musician, foreign_key: true
      t.string :action

      t.timestamps
    end

    add_index :activities, [:musician_id, :created_at]
  end
end
