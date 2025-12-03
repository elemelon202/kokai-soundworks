class LineUserConnection < ApplicationRecord
  belongs_to :user

  validates :line_user_id, uniqueness: true, allow_nil: true
  validates :link_code, uniqueness: true, allow_nil: true

  scope :pending, -> { where(line_user_id: nil).where.not(link_code: nil) }

  before_create :generate_link_code, unless: :link_code?

  def linked?
    line_user_id.present? && connected_at.present?
  end

  def pending?
    link_code.present? && line_user_id.blank?
  end

  def link_to_line_user!(line_user_id, display_name = nil)
    update!(
      line_user_id: line_user_id,
      line_display_name: display_name,
      connected_at: Time.current,
      link_code: nil
    )
  end

  def self.find_by_link_code(code)
    return nil if code.blank?
    find_by(link_code: code.upcase.strip)
  end

  private

  def generate_link_code
    loop do
      self.link_code = SecureRandom.alphanumeric(6).upcase
      break unless self.class.exists?(link_code: link_code)
    end
  end
end
