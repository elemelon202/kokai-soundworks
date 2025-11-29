class CreateProfileViews < ActiveRecord::Migration[7.1]
    def change
      create_table :profile_views do |t|
        t.bigint :viewer_id, null: true
        t.string :viewable_type, null: false
        t.bigint :viewable_id, null: false
        t.datetime :viewed_at, null: false
        t.string :ip_hash

        t.timestamps
      end

      add_index :profile_views, [:viewable_type, :viewable_id, :viewed_at], name: 'index_profile_views_on_viewable_and_time'
      add_index :profile_views, :viewer_id
      add_foreign_key :profile_views, :users, column: :viewer_id, on_delete: :nullify
    end
end
