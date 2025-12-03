class KanbanTask < ApplicationRecord
  belongs_to :band
  belongs_to :created_by, class_name: 'User'
  belongs_to :assigned_to, class_name: 'Musician', optional: true

  STATUSES = %w[to_do in_progress done].freeze

  TASK_TYPES = %w[
    rehearsal
    recording
    writing
    booking
    promotion
    admin
    other
  ].freeze

  validates :name, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :task_type, presence: true, inclusion: { in: TASK_TYPES }
  validates :band, presence: true
  validates :created_by, presence: true

  scope :by_status, ->(status) { where(status: status) }
  scope :by_type, ->(type) { where(task_type: type) }
  scope :overdue, -> { where('deadline < ?', Date.today).where.not(status: 'done') }
  scope :upcoming, -> { where('deadline BETWEEN ? AND ?', Date.today, 7.days.from_now) }
  scope :ordered, -> { order(position: :asc, created_at: :desc) }

  def status_label
    status.titleize.gsub('_', ' ')
  end

  def overdue?
    deadline.present? && deadline < Date.today && status != 'done'
  end
end
