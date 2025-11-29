require "test_helper"

class ActivityTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @musician = musicians(:one)
  end

  test "track creates activity" do
    assert_difference "Activity.count", 1 do
      Activity.track(user: @user, action: :follow, trackable: @musician, musician: @musician)
    end
  end

  test "action_text returns human readable text" do
    activity = Activity.new(action: "follow")
    assert_equal "followed", activity.action_text
  end

  test "icon returns correct icon for each action" do
    assert_equal "fa-user-plus", Activity.new(action: "follow").icon
    assert_equal "fa-award", Activity.new(action: "endorse").icon
    assert_equal "fa-bullhorn", Activity.new(action: "shoutout").icon
  end

  test "icon_color returns correct color for each action" do
    assert_equal "#3b82f6", Activity.new(action: "follow").icon_color
    assert_equal "#C8E938", Activity.new(action: "endorse").icon_color
    assert_equal "#E936AD", Activity.new(action: "shoutout").icon_color
  end
end
