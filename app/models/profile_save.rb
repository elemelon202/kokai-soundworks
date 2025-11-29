class ProfileSave < ApplicationRecord
    belongs_to :user
    belongs_to :saveable, polymorphic: true

    validates :user_id, uniqueness: {
      scope: [:saveable_type, :saveable_id],
      message: "already saved this profile"
    }
 end
