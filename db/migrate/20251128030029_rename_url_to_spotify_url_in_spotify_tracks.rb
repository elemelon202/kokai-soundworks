class RenameUrlToSpotifyUrlInSpotifyTracks < ActiveRecord::Migration[7.1]
  def change
    rename_column :spotify_tracks, :url, :spotify_url
  end
end
