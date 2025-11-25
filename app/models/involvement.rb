class Involvement < ApplicationRecord
  belongs_to :band
  belongs_to :musician

  validates :musician_id, uniqueness: {scope: :band_id, message: "is already in this band"}
end
