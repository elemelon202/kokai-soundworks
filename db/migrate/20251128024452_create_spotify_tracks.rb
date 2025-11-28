class CreateSpotifyTracks < ActiveRecord::Migration[7.1]
  def change
    create_table :spotify_tracks do |t|
      t.references :band, null: false, foreign_key: true
      t.string :spotify_type
      t.string :spotify_id
      t.string :url
      t.integer :position

      t.timestamps
    end
  end
end
