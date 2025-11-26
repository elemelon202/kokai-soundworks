class BandInvitationPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.all  # or filter based on user if needed
    end
  end

  def create?
    user_is_inviter?
  end

  def accept?
    user_is_invited_musician?
  end

  def decline?
    user_is_invited_musician?
  end

  private

  def user_is_inviter?
    record.band.user_id == user.id
  end

  def user_is_invited_musician?
    record.musician.user == user
  end
end
