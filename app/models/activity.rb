class Activity < ApplicationRecord
  belongs_to :user
  belongs_to :trackable, polymorphic: true
  belongs_to :musician, optional: true

  validates :action, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :for_musician, ->(musician) { where(musician: musician) }

  ACTIONS = {
    follow: 'followed',
    endorse: 'endorsed',
    shoutout: 'gave a shoutout to',
    save: 'saved',
    like_short: 'liked a short by',
    comment_short: 'commented on a short by'
  }.freeze

  def self.track(user:, action:, trackable:, musician: nil)
    create(
      user: user,
      action: action.to_s,
      trackable: trackable,
      musician: musician
    )
  end

  def action_text
    ACTIONS[action.to_sym] || action
  end

  def icon
    case action.to_sym
    when :follow then 'fa-user-plus'
    when :endorse then 'fa-award'
    when :shoutout then 'fa-bullhorn'
    when :save then 'fa-bookmark'
    when :like_short then 'fa-heart'
    when :comment_short then 'fa-comment'
    else 'fa-circle'
    end
  end

  def icon_color
    case action.to_sym
    when :follow then '#3b82f6'
    when :endorse then '#C8E938'
    when :shoutout then '#E936AD'
    when :save then '#f59e0b'
    when :like_short then '#ef4444'
    when :comment_short then '#8b5cf6'
    else '#888'
    end
  end
end
