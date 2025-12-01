class GigApplication < ApplicationRecord
  belongs_to :gig
  belongs_to :band

  enum status: { pending: 0, approved: 1, rejected: 2 }

  validates :band_id, uniqueness: { scope: :gig_id, message: "has already applied to this gig" }
end
