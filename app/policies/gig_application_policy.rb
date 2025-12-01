class GigApplicationPolicy < ApplicationPolicy
    def index?
      # Anyone can view their applications dashboard
      user.present?
    end

    def create?
      # User must be a leader of the band applying
      user.present? && user.led_bands.include?(record.band)
    end

    def approve?
      # Only venue owner can approve
      user.present? && record.gig.venue.user_id == user.id
    end

    def reject?
      approve?
    end

    class Scope < ApplicationPolicy::Scope
      def resolve
        scope.all
      end
    end
end
