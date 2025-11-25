class BandPolicy < ApplicationPolicy
  # NOTE: Up to Pundit v2.3.1, the inheritance was declared as
  # `Scope < Scope` rather than `Scope < ApplicationPolicy::Scope`.
  # In most cases the behavior will be identical, but if updating existing
  # code, beware of possible changes to the ancestors:
  # https://gist.github.com/Burgestrand/4b4bc22f31c8a95c425fc0e30d7ef1f5

  class Scope < ApplicationPolicy::Scope
    # NOTE: Be explicit about which records you allow access to!
    def resolve
      scope.all
    end
  end

  def index?
    # public access
    true
  end

  def show?
    # public access
    true
  end

  def new?
    # user can initiate band creation if
    # 1. They are a registered member (logged in)
    # 2. They have a musician profile
    # 3. ***For this to work a user can only have_one musician****
    user.present? && user.musician.present?
  end

  def create?
    #checking if user is a musician so they can make a band - Tyrhen
    user.musician.present?
  end

  def edit?
    user == record.user
  end

  def update?
    edit?
  end

  def destroy?
    user == record.user
  end

  #add access to dashboard (might need to be a different view????)
  #might look something like the below:
  #def dashboard?
  #   Access to the sensitive band dashboard (chat, bookings, tasks) is restricted to:

  #   1. Band Owner
  #   return true if user == record.user

  #   2. Confirmed Band Members
  #   if user.musician.present?
  #      Check if the current user's musician profile is part of the band's list of musicians
  #     return true if record.musicians.include?(user.musician)
  #   end

  #   Deny access otherwise
  #   false
  # end
end
