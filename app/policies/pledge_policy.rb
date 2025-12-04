# frozen_string_literal: true

class PledgePolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    return false unless user
    # Owner can see their pledge, venue owner can see all pledges
    record.user_id == user.id || record.funded_gig.venue.user_id == user.id
  end

  def new?
    create?
  end

  def create?
    return false unless user
    # Anyone can pledge (except venue owner to their own gig)
    record.funded_gig.venue.user_id != user.id
  end

  def cancel?
    return false unless user
    # Only pledge owner can cancel, and only if still authorized
    record.user_id == user.id && record.authorized?
  end

  def my_pledges?
    user.present?
  end

  class Scope < Scope
    def resolve
      if user
        scope.where(user_id: user.id)
      else
        scope.none
      end
    end
  end
end
