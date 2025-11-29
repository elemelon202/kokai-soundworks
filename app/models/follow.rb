class Follow < ApplicationRecord
    belongs_to :follower, class_name: 'User'
    belongs_to :followable, polymorphic: true

    validates :follower_id, uniqueness: {
      scope: [:followable_type, :followable_id],
      message: "already following this profile"
    }
end
