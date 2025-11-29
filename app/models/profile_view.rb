class ProfileView < ApplicationRecord
    belongs_to :viewer, class_name: 'User', optional: true
    belongs_to :viewable, polymorphic: true

    validates :viewed_at, presence: true
end
