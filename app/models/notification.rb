class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :notifiable, polymorphic: true
  belongs_to :actor, class_name: 'User', optional: true

  scope :unread, -> { where(read: false) }
  scope :recent, -> { order(created_at: :desc).limit(20) }

  # Notification types
  TYPES = {
    band_invitation: 'band_invitation',
    band_invitation_accepted: 'band_invitation_accepted',
    band_invitation_declined: 'band_invitation_declined',
    direct_message: 'direct_message',
    band_message: 'band_message',
    band_member_joined: 'band_member_joined',
    band_member_left: 'band_member_left',
    friend_request: 'friend_request',
    friend_request_accepted: 'friend_request_accepted'
  }.freeze

  validates :notification_type, presence: true, inclusion: { in: TYPES.values }

  after_create_commit :broadcast_notification

  def self.create_for_band_invitation(invitation)
    # Notify the musician being invited
    create!(
      user: invitation.musician.user,
      notifiable: invitation,
      notification_type: TYPES[:band_invitation],
      actor: invitation.inviter,
      message: "You've been invited to join #{invitation.band.name}"
    )
  end

  def self.create_for_invitation_response(invitation, accepted:)
    type = accepted ? TYPES[:band_invitation_accepted] : TYPES[:band_invitation_declined]
    status = accepted ? 'accepted' : 'declined'

    # Notify the inviter
    create!(
      user: invitation.inviter,
      notifiable: invitation,
      notification_type: type,
      actor: invitation.musician.user,
      message: "#{invitation.musician.name} has #{status} your invitation to #{invitation.band.name}"
    )
  end

  def self.create_for_direct_message(message)
    chat = message.chat
    return unless chat.direct_message?

    recipient = chat.users.where.not(id: message.user_id).first
    return unless recipient

    create!(
      user: recipient,
      notifiable: message,
      notification_type: TYPES[:direct_message],
      actor: message.user,
      message: "New message from #{message.user.username}"
    )
  end

  def self.create_for_band_message(message, band)
    # Notify all band members except the sender
    band.musicians.each do |musician|
      next if musician.user_id == message.user_id

      create!(
        user: musician.user,
        notifiable: message,
        notification_type: TYPES[:band_message],
        actor: message.user,
        message: "New message in #{band.name} chat"
      )
    end
  end

  def self.create_for_band_member_joined(band, musician)
    # Notify all existing band members
    band.musicians.where.not(id: musician.id).each do |member|
      create!(
        user: member.user,
        notifiable: band,
        notification_type: TYPES[:band_member_joined],
        actor: musician.user,
        message: "#{musician.name} has joined #{band.name}"
      )
    end
  end

  def self.create_for_friend_request(friendship)
    create!(
      user: friendship.addressee,
      notifiable: friendship,
      notification_type: TYPES[:friend_request],
      actor: friendship.requester,
      message: "#{friendship.requester.username} sent you a friend request"
    )
  end

  def self.create_for_friend_request_accepted(friendship)
    create!(
      user: friendship.requester,
      notifiable: friendship,
      notification_type: TYPES[:friend_request_accepted],
      actor: friendship.addressee,
      message: "#{friendship.addressee.username} accepted your friend request"
    )
  end

  def icon_class
    case notification_type
    when TYPES[:band_invitation]
      'fa-solid fa-envelope'
    when TYPES[:band_invitation_accepted]
      'fa-solid fa-check-circle'
    when TYPES[:band_invitation_declined]
      'fa-solid fa-times-circle'
    when TYPES[:direct_message]
      'fa-solid fa-comment'
    when TYPES[:band_message]
      'fa-solid fa-comments'
    when TYPES[:band_member_joined]
      'fa-solid fa-user-plus'
    when TYPES[:band_member_left]
      'fa-solid fa-user-minus'
    when TYPES[:friend_request]
      'fa-solid fa-user-plus'
    when TYPES[:friend_request_accepted]
      'fa-solid fa-user-check'
    else
      'fa-solid fa-bell'
    end
  end

  def path
    return '#' if notifiable.nil?

    case notification_type
    when TYPES[:band_invitation]
      # Link to musician edit page where they can accept/decline
      Rails.application.routes.url_helpers.edit_musician_path(user.musician) if user.musician
    when TYPES[:band_invitation_accepted], TYPES[:band_invitation_declined], TYPES[:band_member_joined]
      Rails.application.routes.url_helpers.band_path(notifiable.band) if notifiable.respond_to?(:band) && notifiable.band
    when TYPES[:direct_message]
      Rails.application.routes.url_helpers.direct_message_path(notifiable.chat) if notifiable.respond_to?(:chat) && notifiable.chat
    when TYPES[:band_message]
      band = notifiable.chat&.band
      Rails.application.routes.url_helpers.edit_band_path(band) if band
    when TYPES[:friend_request], TYPES[:friend_request_accepted]
      Rails.application.routes.url_helpers.friendships_path
    else
      '#'
    end
  end

  private

  def broadcast_notification
    NotificationChannel.broadcast_to(
      user,
      {
        id: id,
        message: message,
        notification_type: notification_type,
        icon_class: icon_class,
        path: path,
        created_at: created_at.iso8601,
        unread_count: user.notifications.unread.count
      }
    )
  end
end
