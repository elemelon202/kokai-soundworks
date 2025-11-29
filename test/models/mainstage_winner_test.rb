require "test_helper"

class MainstageWinnerTest < ActiveSupport::TestCase
  def setup
    @contest = MainstageContest.create!(
      start_date: Date.current.beginning_of_week(:sunday) - 7.days,
      end_date: Date.current.beginning_of_week(:sunday) - 1.day,
      status: 'completed'
    )
    @musician = musicians(:one)
    @winner = MainstageWinner.create!(
      musician: @musician,
      mainstage_contest: @contest,
      final_score: 100,
      engagement_score: 80,
      vote_score: 20
    )
  end

  test "only one winner per contest" do
    duplicate = MainstageWinner.new(
      musician: musicians(:two),
      mainstage_contest: @contest,
      final_score: 50
    )
    assert_not duplicate.valid?
  end

  test "week_label returns formatted date range" do
    label = @winner.week_label
    assert label.include?(@contest.start_date.strftime('%b %d'))
    assert label.include?(@contest.end_date.strftime('%b %d'))
  end

  test "current_spotlight? returns true for most recent winner" do
    assert @winner.current_spotlight?
  end
end
