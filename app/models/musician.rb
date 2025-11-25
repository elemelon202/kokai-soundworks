class Musician < ApplicationRecord
  belongs_to :user

  has_many :involvements, dependent: :destroy
  has_many :bands, through: :involvements
end
