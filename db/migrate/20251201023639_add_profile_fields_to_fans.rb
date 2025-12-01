class AddProfileFieldsToFans < ActiveRecord::Migration[7.1]
  def change
    add_column :fans, :favorite_genres, :string
    add_column :fans, :social_instagram, :string
    add_column :fans, :social_twitter, :string
    add_column :fans, :social_spotify, :string
  end
end
