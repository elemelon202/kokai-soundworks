class Chat < ApplicationRecord
  belongs_to :band, optional: true
  has_many :participations, dependent: :destroy
  has_many :messages, dependent: :destroy
  has_many :users, through: :participations
end
