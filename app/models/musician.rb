class Musician < ApplicationRecord
  # involvements has to come first
  has_many :involvements, dependent: :destroy
  has_many :bands, through: :involvements
  belongs_to :user
  has_one_attached :photo

  validates :name, presence: true
end
