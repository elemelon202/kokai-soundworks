require "test_helper"

class ChallengeTest < ActiveSupport::TestCase
  include ActionDispatch::TestProcess::FixtureFile

  def setup
    @musician = musicians(:one)
    @short = @musician.musician_shorts.create!(
      title: "Test Short",
      video: fixture_file_upload("test_video.mp4", "video/mp4")
    )
    @challenge = Challenge.new(
      creator: @musician,
      original_short: @short,
      title: "Can You Play This?",
      description: "Show me what you got!"
    )
  end

  test "valid challenge" do
    assert @challenge.valid?
  end

  test "requires title" do
    @challenge.title = nil
    assert_not @challenge.valid?
    assert_includes @challenge.errors[:title], "can't be blank"
  end

  test "requires creator" do
    @challenge.creator = nil
    assert_not @challenge.valid?
  end

  test "requires original_short" do
    @challenge.original_short = nil
    assert_not @challenge.valid?
  end

  test "default status is open" do
    @challenge.save!
    assert_equal "open", @challenge.status
  end

  test "status must be valid" do
    @challenge.status = "invalid"
    assert_not @challenge.valid?
  end

  test "start_voting changes status" do
    @challenge.save!
    @challenge.start_voting!
    assert_equal "voting", @challenge.status
  end

  test "close_and_pick_winner selects top voted response" do
    @challenge.save!

    # Create responding musician and their short
    other_musician = musicians(:two)
    other_short = other_musician.musician_shorts.create!(
      title: "Response Short",
      video: fixture_file_upload("test_video.mp4", "video/mp4")
    )

    response = @challenge.challenge_responses.create!(
      musician: other_musician,
      musician_short: other_short
    )

    # Add votes
    3.times do |i|
      user = User.create!(email: "voter#{i}@test.com", password: "password")
      response.challenge_votes.create!(user: user)
    end
    response.reload

    @challenge.close_and_pick_winner!

    assert_equal "closed", @challenge.status
    assert_equal response, @challenge.winner
  end

  test "responded_by? returns true if musician has responded" do
    @challenge.save!
    other_musician = musicians(:two)

    assert_not @challenge.responded_by?(other_musician)

    other_short = other_musician.musician_shorts.create!(
      title: "Response",
      video: fixture_file_upload("test_video.mp4", "video/mp4")
    )

    @challenge.challenge_responses.create!(
      musician: other_musician,
      musician_short: other_short
    )

    assert @challenge.responded_by?(other_musician)
  end
end
