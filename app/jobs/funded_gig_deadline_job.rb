# frozen_string_literal: true

# Run daily to process funding deadlines
# Schedule via Heroku Scheduler: `rails runner "FundedGigDeadlineJob.perform_now"`
class FundedGigDeadlineJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "[FUNDED GIG DEADLINE] Starting deadline processing..."

    process_expired_deadlines
    send_deadline_reminders

    Rails.logger.info "[FUNDED GIG DEADLINE] Deadline processing complete."
  end

  private

  def process_expired_deadlines
    FundedGig.needs_processing.find_each do |funded_gig|
      Rails.logger.info "[FUNDED GIG DEADLINE] Processing deadline for gig #{funded_gig.id}: #{funded_gig.name}"

      result = Stripe::FundedGigProcessingService.new(funded_gig).process!

      Rails.logger.info "[FUNDED GIG DEADLINE] Result for #{funded_gig.id}: #{result[:message]}"
    end
  end

  def send_deadline_reminders
    # 3 days before deadline
    FundedGig.accepting_pledges
             .where(funding_deadline: Date.current + 3.days)
             .find_each do |funded_gig|
      send_reminder(funded_gig, days: 3)
    end

    # 1 day before deadline
    FundedGig.accepting_pledges
             .where(funding_deadline: Date.current + 1.day)
             .find_each do |funded_gig|
      send_reminder(funded_gig, days: 1)
    end
  end

  def send_reminder(funded_gig, days:)
    # Notify existing supporters
    funded_gig.supporters.find_each do |user|
      Notification.create(
        user: user,
        notification_type: 'funded_gig_deadline_reminder',
        notifiable: funded_gig,
        message: "#{days} day#{'s' if days > 1} left to fund #{funded_gig.name}! Currently at #{funded_gig.funding_percentage}% of goal.",
        read: false
      )
    end

    # Notify band followers who haven't pledged
    follower_ids = funded_gig.gig.bands.flat_map { |b| b.followers.pluck(:id) }.uniq
    supporter_ids = funded_gig.supporters.pluck(:id)
    non_pledged_followers = User.where(id: follower_ids - supporter_ids)

    non_pledged_followers.find_each do |user|
      Notification.create(
        user: user,
        notification_type: 'funded_gig_deadline_reminder',
        notifiable: funded_gig,
        message: "#{days} day#{'s' if days > 1} left! Help fund #{funded_gig.name} - #{funded_gig.funding_percentage}% funded.",
        read: false
      )
    end

    Rails.logger.info "[FUNDED GIG DEADLINE] Sent #{days}-day reminders for #{funded_gig.id}"
  end
end
