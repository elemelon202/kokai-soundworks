# frozen_string_literal: true

class FundedGigPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  def new?
    create?
  end

  def create?
    return false unless user
    # Only venue owner can create funded gigs for their gigs
    record.gig.venue.user_id == user.id
  end

  def edit?
    update?
  end

  def update?
    return false unless user
    # Venue owner can update
    record.venue.user_id == user.id
  end

  def destroy?
    update?
  end

  class Scope < Scope
    def resolve
      scope.all
    end
  end
end
