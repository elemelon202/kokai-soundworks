class BandPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.all
    end
  end

  def show?
    true
  end

  def create?
    user.present?
  end

  def new?
    create?
  end

  def edit?
    return false unless user.present?
    user_is_owner? || user_is_member?
  end

  def update?
    edit?
  end

  def destroy?
    return false unless user.present?
    user_is_owner?
  end

  def purge_attachment?
    edit?
  end

  private

  def user_is_owner?
    record.user_id == user.id
  end

  def user_is_member?
    # Check if user has a musician profile that's part of this band
    return false unless user.musician
    record.musicians.include?(user.musician)
  end
end
