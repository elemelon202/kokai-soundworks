require "test_helper"

class BandMainstageContestTest < ActiveSupport::TestCase
  def setup
    @contest = BandMainstageContest.create!(
      start_date: Date.current.beginning_of_week(:sunday),
      end_date: Date.current.beginning_of_week(:sunday) + 6.days,
      status: 'active'
    )
  end

  test "current_contest returns existing active contest" do
    assert_equal @contest, BandMainstageContest.current_contest
  end

  test "current_contest creates new contest if none exists" do
    @contest.destroy
    assert_difference "BandMainstageContest.count", 1 do
      BandMainstageContest.current_contest
    end
  end

  test "end_date must be after start_date" do
    contest = BandMainstageContest.new(start_date: Date.current, end_date: Date.current - 1.day)
    assert_not contest.valid?
  end

  test "active? returns true for current active contest" do
    assert @contest.active?
  end

  test "ended? returns true when past end_date" do
    @contest.update!(end_date: Date.current - 1.day)
    assert @contest.ended?
  end

  test "leaderboard returns bands sorted by score" do
    leaderboard = @contest.leaderboard(10)
    assert leaderboard.is_a?(Array)
  end

  test "ACCOUNT_AGE_REQUIREMENT is 3 days" do
    assert_equal 3.days, BandMainstageContest::ACCOUNT_AGE_REQUIREMENT
  end

  test "MAX_POINTS_PER_USER is 15" do
    assert_equal 15, BandMainstageContest::MAX_POINTS_PER_USER
  end
end
