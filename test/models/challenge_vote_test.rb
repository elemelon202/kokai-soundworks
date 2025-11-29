require "test_helper"

class ChallengeVoteTest < ActiveSupport::TestCase
  include ActionDispatch::TestProcess::FixtureFile

  def setup
    @creator = musicians(:one)
    @responder = musicians(:two)
    @voter = users(:one)

    # Make voter different from responder's user
    @voter.update!(created_at: 1.month.ago) if @voter == @responder.user

    @creator_short = @creator.musician_shorts.create!(
      title: "Challenge Short",
      video: fixture_file_upload("test_video.mp4", "video/mp4")
    )

    @challenge = Challenge.create!(
      creator: @creator,
      original_short: @creator_short,
      title: "Test Challenge"
    )

    @responder_short = @responder.musician_shorts.create!(
      title: "Response Short",
      video: fixture_file_upload("test_video.mp4", "video/mp4")
    )

    @response = ChallengeResponse.create!(
      challenge: @challenge,
      musician: @responder,
      musician_short: @responder_short
    )
  end

  test "valid vote" do
    new_voter = User.create!(email: "newvoter@test.com", password: "password")
    vote = ChallengeVote.new(user: new_voter, challenge_response: @response)
    assert vote.valid?
  end

  test "one vote per user per response" do
    new_voter = User.create!(email: "newvoter@test.com", password: "password")
    ChallengeVote.create!(user: new_voter, challenge_response: @response)

    duplicate = ChallengeVote.new(user: new_voter, challenge_response: @response)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_id], "has already voted for this response"
  end

  test "cannot vote for closed challenge" do
    @challenge.update!(status: 'closed')
    new_voter = User.create!(email: "newvoter@test.com", password: "password")

    vote = ChallengeVote.new(user: new_voter, challenge_response: @response)
    assert_not vote.valid?
    assert_includes vote.errors[:base], "This challenge is closed for voting"
  end

  test "cannot vote for own response" do
    vote = ChallengeVote.new(user: @responder.user, challenge_response: @response)
    assert_not vote.valid?
    assert_includes vote.errors[:base], "You cannot vote for your own response"
  end

  test "increments response votes_count" do
    new_voter = User.create!(email: "newvoter@test.com", password: "password")

    assert_difference -> { @response.reload.votes_count }, 1 do
      ChallengeVote.create!(user: new_voter, challenge_response: @response)
    end
  end
end
