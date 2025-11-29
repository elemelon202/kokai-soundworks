namespace :band_mainstage do
  desc "Finalize ended BAND MAINSTAGE contests and pick winners"
  task finalize: :environment do
    BandMainstageFinalizationJob.perform_now
  end

  desc "Show current BAND MAINSTAGE contest status"
  task status: :environment do
    contest = BandMainstageContest.current_contest
    puts "Current Band Contest: #{contest.start_date} - #{contest.end_date}"
    puts "Status: #{contest.status}"
    puts "Days remaining: #{(contest.end_date - Date.current).to_i}"
    puts ""
    puts "Top 5 Leaderboard:"
    contest.leaderboard(5).each_with_index do |entry, i|
      puts "  #{i + 1}. #{entry[:band].name} - #{entry[:total_score]} pts"
    end
  end
end
