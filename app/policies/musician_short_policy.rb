class MusicianShortPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
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
    user.present? && user_owns_musician?
  end

  def create?
    new?
  end

  def edit?
    user.present? && user_owns_musician?
  end

  def update?
    edit?
  end

  def destroy?
    edit?
  end

  def reorder?
    user.present? && user_owns_musician?
  end

  private

  def user_owns_musician?
    # record is the MusicianShort, record.musician is the Musician
    record.musician.user_id == user.id
  end
end
