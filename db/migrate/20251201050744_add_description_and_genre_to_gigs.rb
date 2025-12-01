class AddDescriptionAndGenreToGigs < ActiveRecord::Migration[7.1]
  def change
    add_column :gigs, :description, :text
    add_column :gigs, :genre, :string
  end
end
