class NotificationsController < ApplicationController
  before_action :authenticate_user!
  skip_after_action :verify_policy_scoped
  skip_after_action :verify_authorized

  def index
    @notifications = current_user.notifications.recent.includes(:actor, :notifiable)
    @unread_count = current_user.notifications.unread.count

    respond_to do |format|
      format.html
      format.json do
        render json: {
          notifications: @notifications.map { |n| notification_json(n) },
          unread_count: @unread_count
        }
      end
    end
  end

  def mark_as_read
    @notification = current_user.notifications.find(params[:id])
    @notification.update(read: true)

    respond_to do |format|
      format.html { redirect_to @notification.path || notifications_path }
      format.json { render json: { success: true, unread_count: current_user.notifications.unread.count } }
    end
  end

  def mark_all_as_read
    current_user.notifications.unread.update_all(read: true)

    respond_to do |format|
      format.html { redirect_to notifications_path, notice: 'All notifications marked as read' }
      format.json { render json: { success: true, unread_count: 0 } }
    end
  end

  private

  def notification_json(notification)
    {
      id: notification.id,
      message: notification.message,
      notification_type: notification.notification_type,
      icon_class: notification.icon_class,
      path: notification.path,
      read: notification.read,
      created_at: notification.created_at.iso8601,
      time_ago: time_ago_in_words(notification.created_at)
    }
  end

  def time_ago_in_words(time)
    seconds = (Time.current - time).to_i

    case seconds
    when 0..59 then "Just now"
    when 60..3599 then "#{seconds / 60}m ago"
    when 3600..86399 then "#{seconds / 3600}h ago"
    when 86400..604799 then "#{seconds / 86400}d ago"
    else time.strftime("%b %d")
    end
  end
end
