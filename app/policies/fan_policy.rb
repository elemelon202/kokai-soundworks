class FanPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end

  def show?
    true
  end

  def edit?
    return false unless user.present?
    user.fan == record
  end

  def update?
    edit?
  end

  def gigs?
    true
  end

  def following?
    true
  end

  def saved?
    return false unless user.present?
    user.fan == record
  end

  def friends?
    true
  end
end
