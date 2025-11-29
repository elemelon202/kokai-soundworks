require "test_helper"

class ChallengeResponseTest < ActiveSupport::TestCase
  include ActionDispatch::TestProcess::FixtureFile

  def setup
    @creator = musicians(:one)
    @responder = musicians(:two)

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
  end

  test "valid response" do
    response = ChallengeResponse.new(
      challenge: @challenge,
      musician: @responder,
      musician_short: @responder_short
    )
    assert response.valid?
  end

  test "cannot respond to own challenge" do
    creator_response_short = @creator.musician_shorts.create!(
      title: "Self Response",
      video: fixture_file_upload("test_video.mp4", "video/mp4")
    )

    response = ChallengeResponse.new(
      challenge: @challenge,
      musician: @creator,
      musician_short: creator_response_short
    )

    assert_not response.valid?
    assert_includes response.errors[:base], "You cannot respond to your own challenge"
  end

  test "one response per musician per challenge" do
    ChallengeResponse.create!(
      challenge: @challenge,
      musician: @responder,
      musician_short: @responder_short
    )

    another_short = @responder.musician_shorts.create!(
      title: "Another Response",
      video: fixture_file_upload("test_video.mp4", "video/mp4")
    )

    duplicate = ChallengeResponse.new(
      challenge: @challenge,
      musician: @responder,
      musician_short: another_short
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:musician_id], "has already responded to this challenge"
  end

  test "increments challenge responses_count" do
    assert_difference -> { @challenge.reload.responses_count }, 1 do
      ChallengeResponse.create!(
        challenge: @challenge,
        musician: @responder,
        musician_short: @responder_short
      )
    end
  end
end
