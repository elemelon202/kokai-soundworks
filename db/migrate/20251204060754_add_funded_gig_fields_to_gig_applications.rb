class AddFundedGigFieldsToGigApplications < ActiveRecord::Migration[7.1]
  def change
    add_column :gig_applications, :mainstage_score_at_application, :integer, default: 0
    add_column :gig_applications, :follower_count_at_application, :integer, default: 0
    add_column :gig_applications, :past_gig_count, :integer, default: 0
  end
end
