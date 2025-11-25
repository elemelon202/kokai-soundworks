class Message < ApplicationRecord
  belongs_to :chat
  belongs_to :user
  has_many :attachments, dependent: :destroy
end
