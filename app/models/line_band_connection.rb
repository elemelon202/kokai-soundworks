class LineBandConnection < ApplicationRecord
  belongs_to :band
  belongs_to :linked_by, class_name: 'User', optional: true
  has_many :line_pending_events, dependent: :destroy

  validates :line_group_id, uniqueness: true, allow_nil: true
  validates :link_code, uniqueness: true, allow_nil: true

  scope :active, -> { where(active: true) }
  scope :pending, -> { where(line_group_id: nil).where.not(link_code: nil) }

  before_create :generate_link_code, unless: :link_code?

  def linked?
    line_group_id.present?
  end

  def pending?
    link_code.present? && line_group_id.blank?
  end

  def link_to_group!(group_id)
    update!(
      line_group_id: group_id,
      linked_at: Time.current,
      active: true
    )
  end

  def self.find_by_link_code(code)
    return nil if code.blank?
    find_by(link_code: code.upcase.strip)
  end

  private

  def generate_link_code
    loop do
      self.link_code = SecureRandom.alphanumeric(8).upcase
      break unless self.class.exists?(link_code: link_code)
    end
  end
end
