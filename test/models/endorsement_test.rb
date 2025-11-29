require "test_helper"

class EndorsementTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @musician = musicians(:one)
  end

  test "valid endorsement" do
    endorsement = Endorsement.new(user: @user, musician: @musician, skill: "Guitar")
    assert endorsement.valid?
  end

  test "requires skill" do
    endorsement = Endorsement.new(user: @user, musician: @musician, skill: nil)
    assert_not endorsement.valid?
  end

  test "user can only endorse same skill once per musician" do
    Endorsement.create!(user: @user, musician: @musician, skill: "Guitar")
    duplicate = Endorsement.new(user: @user, musician: @musician, skill: "Guitar")
    assert_not duplicate.valid?
  end

  test "user can endorse different skills for same musician" do
    Endorsement.create!(user: @user, musician: @musician, skill: "Guitar")
    different_skill = Endorsement.new(user: @user, musician: @musician, skill: "Drums")
    assert different_skill.valid?
  end

  test "SKILLS constant contains expected skills" do
    assert_includes Endorsement::SKILLS, "Guitar"
    assert_includes Endorsement::SKILLS, "Vocals"
    assert_includes Endorsement::SKILLS, "Drums"
  end
end
