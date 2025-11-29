require "test_helper"

class ShoutoutTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @musician = musicians(:one)
  end

  test "valid shoutout" do
    shoutout = Shoutout.new(user: @user, musician: @musician, content: "Amazing performer!")
    assert shoutout.valid?
  end

  test "requires content" do
    shoutout = Shoutout.new(user: @user, musician: @musician, content: nil)
    assert_not shoutout.valid?
  end

  test "content max length is 500" do
    shoutout = Shoutout.new(user: @user, musician: @musician, content: "a" * 501)
    assert_not shoutout.valid?
  end

  test "user can only give one shoutout per musician" do
    Shoutout.create!(user: @user, musician: @musician, content: "First shoutout")
    duplicate = Shoutout.new(user: @user, musician: @musician, content: "Second shoutout")
    assert_not duplicate.valid?
  end
end
