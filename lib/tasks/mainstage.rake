namespace :mainstage do
  desc "Finalize ended MAINSTAGE contests and pick winners"
  task finalize: :environment do
    MainstageFinalizationJob.perform_now
  end

  desc "Show current MAINSTAGE contest status"
  task status: :environment do
    contest = MainstageContest.current_contest
    puts "Current Contest: #{contest.start_date} - #{contest.end_date}"
    puts "Status: #{contest.status}"
    puts "Days remaining: #{(contest.end_date - Date.current).to_i}"
    puts ""
    puts "Top 5 Leaderboard:"
    contest.leaderboard(5).each_with_index do |entry, i|
      puts "  #{i + 1}. #{entry[:musician].name} - #{entry[:total_score]} pts"
    end
  end
end
