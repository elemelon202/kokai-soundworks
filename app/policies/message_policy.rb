class MessagePolicy < ApplicationPolicy

  # Anyone in the chat can see messages
  def index?
    user_is_participant?
  end

  # Anyone in the chat can send messages
  def create?
    user_is_participant?
  end

  # Anyone in the chat can view a single message
  def show?
    user_is_participant?
  end

  private

  def user_is_participant?
    record.chat.participations.exists?(user: user)
  end
end
