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
    friend_request_accepted: 'friend_request_accepted',
    mainstage_win: 'mainstage_win',
    band_mainstage_win: 'band_mainstage_win',
    endorsement: 'endorsement',
    shoutout: 'shoutout',
    new_follower: 'new_follower',
    challenge_response: 'challenge_response',
    challenge_win: 'challenge_win',
    band_gig_announcement: 'band_gig_announcement'
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

  def self.create_for_mainstage_win(winner)
    create!(
      user: winner.musician.user,
      notifiable: winner,
      notification_type: TYPES[:mainstage_win],
      message: "Congratulations! You won MAINSTAGE for #{winner.week_label} with #{winner.final_score} points!"
    )
  end

  def self.create_for_band_mainstage_win(winner)
    # Notify all band members
    winner.band.musicians.each do |musician|
      create!(
        user: musician.user,
        notifiable: winner,
        notification_type: TYPES[:band_mainstage_win],
        message: "Congratulations! #{winner.band.name} won BAND MAINSTAGE for #{winner.week_label} with #{winner.final_score} points!"
      )
    end
  end

  def self.create_for_endorsement(endorsement)
    return if endorsement.musician.user == endorsement.user # Don't notify self

    actor_name = endorsement.user.musician&.name || endorsement.user.email.split('@').first
    create!(
      user: endorsement.musician.user,
      notifiable: endorsement,
      notification_type: TYPES[:endorsement],
      actor: endorsement.user,
      message: "#{actor_name} endorsed you for #{endorsement.skill}"
    )
  end

  def self.create_for_shoutout(shoutout)
    return if shoutout.musician.user == shoutout.user # Don't notify self

    actor_name = shoutout.user.musician&.name || shoutout.user.email.split('@').first
    create!(
      user: shoutout.musician.user,
      notifiable: shoutout,
      notification_type: TYPES[:shoutout],
      actor: shoutout.user,
      message: "#{actor_name} gave you a shoutout!"
    )
  end

  def self.create_for_new_follower(follow)
    return unless follow.followable_type == 'Musician'

    musician = follow.followable
    return if musician.user == follow.follower # Don't notify self

    actor_name = follow.follower.musician&.name || follow.follower.email.split('@').first
    create!(
      user: musician.user,
      notifiable: follow,
      notification_type: TYPES[:new_follower],
      actor: follow.follower,
      message: "#{actor_name} started following you"
    )
  end

  def self.create_for_band_gig_announcement(booking)
    band = booking.band
    gig = booking.gig
    venue = gig.venue

    # Notify all followers of the band
    band.followers.find_each do |follower|
      # Don't notify band members
      next if band.musicians.exists?(user_id: follower.id)

      create!(
        user: follower,
        notifiable: booking,
        notification_type: TYPES[:band_gig_announcement],
        message: "#{band.name} is playing at #{venue.name} on #{gig.date.strftime('%b %d, %Y')}!"
      )
    end
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
    when TYPES[:mainstage_win]
      'fa-solid fa-trophy'
    when TYPES[:band_mainstage_win]
      'fa-solid fa-trophy'
    when TYPES[:endorsement]
      'fa-solid fa-award'
    when TYPES[:shoutout]
      'fa-solid fa-bullhorn'
    when TYPES[:new_follower]
      'fa-solid fa-heart'
    when TYPES[:challenge_response]
      'fa-solid fa-guitar'
    when TYPES[:challenge_win]
      'fa-solid fa-trophy'
    when TYPES[:band_gig_announcement]
      'fa-solid fa-calendar-star'
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
    when TYPES[:mainstage_win]
      Rails.application.routes.url_helpers.mainstage_path
    when TYPES[:band_mainstage_win]
      Rails.application.routes.url_helpers.band_mainstage_path
    when TYPES[:endorsement], TYPES[:shoutout], TYPES[:new_follower]
      Rails.application.routes.url_helpers.musician_path(user.musician) if user.musician
    when TYPES[:challenge_response], TYPES[:challenge_win]
      if notifiable.respond_to?(:challenge)
        Rails.application.routes.url_helpers.challenge_path(notifiable.challenge)
      elsif notifiable.is_a?(Challenge)
        Rails.application.routes.url_helpers.challenge_path(notifiable)
      else
        Rails.application.routes.url_helpers.challenges_path
      end
    when TYPES[:band_gig_announcement]
      if notifiable.respond_to?(:gig) && notifiable.gig
        Rails.application.routes.url_helpers.gig_path(notifiable.gig)
      else
        '#'
      end
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
