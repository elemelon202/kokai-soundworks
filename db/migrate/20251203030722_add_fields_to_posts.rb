class AddFieldsToPosts < ActiveRecord::Migration[7.1]
  def change
    add_column :posts, :instrument, :string
    add_column :posts, :location, :string
    add_column :posts, :genre, :string
    add_column :posts, :needed_by, :date
    add_column :posts, :active, :boolean, default: true

    add_index :posts, :needed_by
    add_index :posts, :active
  end
end
