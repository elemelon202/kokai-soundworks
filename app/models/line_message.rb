class LineMessage < ApplicationRecord
  validates :line_group_id, presence: true
  validates :content, presence: true
  validates :sent_at, presence: true
  validates :message_id, uniqueness: true, allow_nil: true

  scope :for_group, ->(group_id) { where(line_group_id: group_id) }
  scope :unprocessed, -> { where(processed_at: nil) }

  def self.unprocessed_for_group(group_id, limit: 50)
    for_group(group_id)
      .unprocessed
      .order(sent_at: :asc)
      .limit(limit)
  end

  def self.mark_as_processed(group_id)
    for_group(group_id)
      .unprocessed
      .update_all(processed_at: Time.current)
  end

  def self.format_conversation(messages)
    messages.map do |msg|
      name = msg.display_name || "Someone"
      "#{name}: #{msg.content}"
    end.join("\n")
  end
end
