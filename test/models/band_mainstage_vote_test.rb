require "test_helper"

class BandMainstageVoteTest < ActiveSupport::TestCase
  def setup
    @contest = BandMainstageContest.create!(
      start_date: Date.current.beginning_of_week(:sunday),
      end_date: Date.current.beginning_of_week(:sunday) + 6.days,
      status: 'active'
    )
    @user = users(:one)
    @user.update!(created_at: 1.month.ago) # Make account old enough
    @band = bands(:two) # Different band
  end

  test "valid vote" do
    vote = BandMainstageVote.new(user: @user, band: @band, band_mainstage_contest: @contest)
    assert vote.valid?
  end

  test "user can only vote once per contest" do
    BandMainstageVote.create!(user: @user, band: @band, band_mainstage_contest: @contest)
    duplicate = BandMainstageVote.new(user: @user, band: bands(:one), band_mainstage_contest: @contest)
    assert_not duplicate.valid?
  end

  test "cannot vote for your own band" do
    band = bands(:one)
    musician = musicians(:one)
    # Ensure the musician is in the band
    Involvement.find_or_create_by!(musician: musician, band: band)

    band_member_user = musician.user
    band_member_user.update!(created_at: 1.month.ago)

    vote = BandMainstageVote.new(user: band_member_user, band: band, band_mainstage_contest: @contest)
    assert_not vote.valid?
    assert vote.errors[:base].include?("You cannot vote for your own band")
  end

  test "account must be old enough to vote" do
    new_user = User.create!(email: "new@test.com", password: "password", created_at: 1.day.ago)
    vote = BandMainstageVote.new(user: new_user, band: @band, band_mainstage_contest: @contest)
    assert_not vote.valid?
  end
end
