class KanbanTask < ApplicationRecord
  belongs_to :created_by, class_name: 'User'

  # Status options for kanban board
  STATUSES = %w[to_do in_progress review done].freeze

  # Task types specific to band work
  TASK_TYPES = %w[
    rehearsal
    recording
    mixing
    mastering
    composition
    lyrics
    arrangement
    booking
    promotion
    equipment
    admin
    other
  ].freeze

  validates :name, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :task_type, presence: true, inclusion: { in: TASK_TYPES }
  validates :created_by, presence: true

  scope :by_status, ->(status) { where(status: status) }
  scope :by_type, ->(type) { where(task_type: type) }
  scope :overdue, -> { where('deadline < ?', Date.today).where.not(status: 'done') }
  scope :upcoming, -> { where('deadline BETWEEN ? AND ?', Date.today, 7.days.from_now) }
  scope :ordered, -> { order(position: :asc, created_at: :desc) }
end
