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

  desc "Finalize ALL MAINSTAGE contests (Musicians + Bands), announce winners, create new week"
  task rotate_all: :environment do
    puts "[MAINSTAGE] Starting weekly rotation at #{Time.current}"
    puts ""

    # Finalize Musician MAINSTAGE
    puts "=== MUSICIAN MAINSTAGE ==="
    MainstageFinalizationJob.perform_now
    mc = MainstageContest.current_contest
    puts "New contest: #{mc.start_date} - #{mc.end_date}"
    mw = MainstageWinner.order(created_at: :desc).first
    if mw && mw.created_at > 1.hour.ago
      puts "Winner announced: #{mw.musician.name} (#{mw.final_score} pts)"
    end
    puts ""

    # Finalize Band MAINSTAGE
    puts "=== BAND MAINSTAGE ==="
    BandMainstageFinalizationJob.perform_now
    bc = BandMainstageContest.current_contest
    puts "New contest: #{bc.start_date} - #{bc.end_date}"
    bw = BandMainstageWinner.order(created_at: :desc).first
    if bw && bw.created_at > 1.hour.ago
      puts "Winner announced: #{bw.band.name} (#{bw.final_score} pts)"
    end

    puts ""
    puts "[MAINSTAGE] Weekly rotation complete!"
  end
end
