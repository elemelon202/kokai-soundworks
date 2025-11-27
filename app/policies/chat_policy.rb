class ChatPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      # Users can see chats they participate in
      scope.joins(:participations).where(participations: { user_id: user.id })
    end
  end

  def index?
    true
  end

  def show?
    # User must be a participant
    record.users.include?(user)
  end

  def create?
    true
  end

  def create_or_show?
    true
  end

  def destroy?
    # User must be a participant in the chat
    record.users.include?(user)
  end
end
