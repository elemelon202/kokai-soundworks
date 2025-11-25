class Chat < ApplicationRecord
  has_many :participations, dependent: :destroy
  has_many :messages, dependent: :destroy
end
