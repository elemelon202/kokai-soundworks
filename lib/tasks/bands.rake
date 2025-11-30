namespace :bands do
  desc "Make all existing band members follow their bands"
  task auto_follow_members: :environment do
    puts "Auto-following bands for existing members..."
    count = 0
    
    Involvement.includes(:band, musician: :user).find_each do |involvement|
      next unless involvement.musician&.user
      
      user = involvement.musician.user
      band = involvement.band
      
      unless user.followed_bands.include?(band)
        user.followed_bands << band
        count += 1
        puts "  #{user.username} now follows #{band.name}"
      end
    end
    
    puts "Done! #{count} new follows created."
  end
end
