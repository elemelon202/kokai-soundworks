class AddSocialStatsToBands < ActiveRecord::Migration[7.1]
  def change
    add_column :bands, :instagram_handle, :string
    add_column :bands, :instagram_followers, :integer, default: 0
    add_column :bands, :tiktok_handle, :string
    add_column :bands, :tiktok_followers, :integer, default: 0
    add_column :bands, :youtube_handle, :string
    add_column :bands, :youtube_subscribers, :integer, default: 0
    add_column :bands, :twitter_handle, :string
    add_column :bands, :twitter_followers, :integer, default: 0
  end
end
