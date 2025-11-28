class SpotifyTrack < ApplicationRecord
  belongs_to :band

  before_validation :parse_spotify_url

  default_scope { order(:position) }

  def embed_url
    "https://open.spotify.com/embed/#{spotify_type}/#{spotify_id}?utm_source=generator&theme=0"
  end

  def embed_height
    case spotify_type
    when 'track' then 152
    else 450
    end
  end

  private
  def parse_spotify_url
    return if spotify_url.blank?

   patterns = [
     %r{open\.spotify\.com/(track|album|artist|playlist)/([a-zA-Z0-9]+)},
      /spotify:(\w+):([a-zA-Z0-9]+)/
   ]

   patterns.each do |pattern|
     match_data = spotify_url.match(pattern)
     if match_data
       self.spotify_type = match_data[1]
       self.spotify_id = match_data[2]
       break
     end
   end
   errors.add(:spotify_url, 'is not a valid Spotify URL') if spotify_type.blank? || spotify_id.blank?
  end
end
