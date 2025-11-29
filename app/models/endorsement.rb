class Endorsement < ApplicationRecord
  belongs_to :user
  belongs_to :musician

  validates :skill, presence: true
  validates :user_id, uniqueness: { scope: [:musician_id, :skill], message: "has already endorsed this skill" }

  # Common skills users can endorse
  SKILLS = [
    'Guitar', 'Bass', 'Drums', 'Vocals', 'Piano', 'Keyboard',
    'Saxophone', 'Violin', 'Trumpet', 'Songwriting', 'Production',
    'Stage Presence', 'Improvisation', 'Music Theory', 'Mixing'
  ].freeze

  scope :for_skill, ->(skill) { where(skill: skill) }
end
