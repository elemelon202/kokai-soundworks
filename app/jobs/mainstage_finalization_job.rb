# Scheduled job to finalize MAINSTAGE contests and pick winners
# Run this weekly on Sunday at midnight to finalize the previous week's contest
#
# To schedule with Heroku Scheduler or cron:
#   bin/rails mainstage:finalize
#
# Or call directly:
#   MainstageFinalizationJob.perform_now

class MainstageFinalizationJob < ApplicationJob
  queue_as :default

  def perform
    # Find all active contests that have ended
    ended_contests = MainstageContest.active.where('end_date < ?', Date.current)

    ended_contests.each do |contest|
      Rails.logger.info "[MAINSTAGE] Finalizing contest #{contest.id} (#{contest.start_date} - #{contest.end_date})"

      contest.finalize!

      # Notify the winner
      if contest.mainstage_winner.present?
        notify_winner(contest.mainstage_winner)
        Rails.logger.info "[MAINSTAGE] Winner: #{contest.mainstage_winner.musician.name} with #{contest.mainstage_winner.final_score} points"
      end
    end

    # Ensure next week's contest exists
    MainstageContest.current_contest

    Rails.logger.info "[MAINSTAGE] Finalization complete. Processed #{ended_contests.count} contest(s)."
  end

  private

  def notify_winner(winner)
    Notification.create_for_mainstage_win(winner)
  end
end
