class GigAttendance < ApplicationRecord
  belongs_to :gig
  belongs_to :user

  enum status: { interested: 0, going: 1, attended: 2 }

  validates :user_id, uniqueness: { scope: :gig_id, message: "already has attendance for this gig" }
end
