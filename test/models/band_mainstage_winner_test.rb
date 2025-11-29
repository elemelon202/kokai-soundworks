require "test_helper"

class BandMainstageWinnerTest < ActiveSupport::TestCase
  def setup
    @contest = BandMainstageContest.create!(
      start_date: Date.current.beginning_of_week(:sunday) - 7.days,
      end_date: Date.current.beginning_of_week(:sunday) - 1.day,
      status: 'completed'
    )
    @band = bands(:one)
    @winner = BandMainstageWinner.create!(
      band: @band,
      band_mainstage_contest: @contest,
      final_score: 100,
      engagement_score: 80,
      vote_score: 20
    )
  end

  test "only one winner per contest" do
    duplicate = BandMainstageWinner.new(
      band: bands(:two),
      band_mainstage_contest: @contest,
      final_score: 50
    )
    assert_not duplicate.valid?
  end

  test "week_label returns formatted date range" do
    label = @winner.week_label
    assert label.include?(@contest.start_date.strftime('%b %d'))
    assert label.include?(@contest.end_date.strftime('%b %d'))
  end
end
