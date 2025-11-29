class Friendship < ApplicationRecord
    belongs_to :requester, class_name: 'User'
    belongs_to :addressee, class_name: 'User'

    validates :requester_id, uniqueness: { scope: :addressee_id, message: "already sent a friend request" }
    validate :not_self

    enum status: { pending: 'pending', accepted: 'accepted', declined: 'declined', blocked: 'blocked' } #all the statuses of a request

    scope :accepted, -> { where(status: 'accepted') }
    scope :pending, -> { where(status: 'pending') }

    private

    def not_self
      errors.add(:addressee_id, "can't be yourself") if requester_id == addressee_id
    end
end
