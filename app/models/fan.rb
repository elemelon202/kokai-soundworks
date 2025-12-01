class Fan < ApplicationRecord
  belongs_to :user
  has_one_attached :avatar
  has_one_attached :banner
end
