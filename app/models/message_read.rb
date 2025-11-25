class MessageRead < ApplicationRecord
  belongs_to :message
  belongs_to :user


  scope :unread, -> { where(read: false) }
end
