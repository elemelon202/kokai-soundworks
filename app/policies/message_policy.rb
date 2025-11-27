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

  # Only the message author can delete
  def destroy?
    user.present? && record.user == user
  end

  private

  def user_is_participant?
    chat = record.chat
    # Check direct participation (for DMs)
    return true if chat.participations.exists?(user: user)

    # Check band membership (for band chats)
    if chat.band.present?
      return true if chat.band.user_id == user.id # Band owner
      return true if user.musician && chat.band.musicians.include?(user.musician)
    end

    false
  end
end
