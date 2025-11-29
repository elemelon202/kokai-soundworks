# Scheduled job to finalize BAND MAINSTAGE contests and pick winners
# Run this weekly on Sunday at midnight to finalize the previous week's contest
#
# To schedule with Heroku Scheduler or cron:
#   bin/rails band_mainstage:finalize
#
# Or call directly:
#   BandMainstageFinalizationJob.perform_now

class BandMainstageFinalizationJob < ApplicationJob
  queue_as :default

  def perform
    # Find all active contests that have ended
    ended_contests = BandMainstageContest.active.where('end_date < ?', Date.current)

    ended_contests.each do |contest|
      Rails.logger.info "[BAND MAINSTAGE] Finalizing contest #{contest.id} (#{contest.start_date} - #{contest.end_date})"

      contest.finalize!

      # Notify the winning band members
      if contest.band_mainstage_winner.present?
        notify_winner(contest.band_mainstage_winner)
        Rails.logger.info "[BAND MAINSTAGE] Winner: #{contest.band_mainstage_winner.band.name} with #{contest.band_mainstage_winner.final_score} points"
      end
    end

    # Ensure next week's contest exists
    BandMainstageContest.current_contest

    Rails.logger.info "[BAND MAINSTAGE] Finalization complete. Processed #{ended_contests.count} contest(s)."
  end

  private

  def notify_winner(winner)
    Notification.create_for_band_mainstage_win(winner)
  end
end
