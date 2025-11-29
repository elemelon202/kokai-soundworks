require "test_helper"

class MainstageVoteTest < ActiveSupport::TestCase
  def setup
    @contest = MainstageContest.create!(
      start_date: Date.current.beginning_of_week(:sunday),
      end_date: Date.current.beginning_of_week(:sunday) + 6.days,
      status: 'active'
    )
    @user = users(:one)
    @user.update!(created_at: 1.month.ago) # Make account old enough
    @musician = musicians(:two) # Different musician
  end

  test "valid vote" do
    vote = MainstageVote.new(user: @user, musician: @musician, mainstage_contest: @contest)
    assert vote.valid?
  end

  test "user can only vote once per contest" do
    MainstageVote.create!(user: @user, musician: @musician, mainstage_contest: @contest)
    duplicate = MainstageVote.new(user: @user, musician: musicians(:one), mainstage_contest: @contest)
    assert_not duplicate.valid?
  end

  test "cannot vote for yourself" do
    user_with_musician = @musician.user
    user_with_musician.update!(created_at: 1.month.ago)
    vote = MainstageVote.new(user: user_with_musician, musician: @musician, mainstage_contest: @contest)
    assert_not vote.valid?
    assert vote.errors[:base].include?("You cannot vote for yourself")
  end

  test "account must be old enough to vote" do
    new_user = User.create!(email: "new@test.com", password: "password", created_at: 1.day.ago)
    vote = MainstageVote.new(user: new_user, musician: @musician, mainstage_contest: @contest)
    assert_not vote.valid?
  end
end
