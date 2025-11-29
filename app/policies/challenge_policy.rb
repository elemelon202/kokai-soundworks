class ChallengePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.all
    end
  end

  def index?
    true
  end

  def show?
    true
  end

  def new?
    user&.musician.present?
  end

  def create?
    user&.musician.present?
  end

  def respond?
    user&.musician.present? && user.musician != record.creator
  end

  def submit_response?
    respond?
  end

  def vote?
    user.present?
  end

  def unvote?
    user.present?
  end

  def start_voting?
    user&.musician == record.creator
  end

  def close?
    user&.musician == record.creator
  end

  def pick_winner?
    user&.musician == record.creator
  end
end
