class Musician < ApplicationRecord
  belongs_to :user
  has_many :bands, through: :involvements
  has_many :involvements, dependent: :destroy
end
