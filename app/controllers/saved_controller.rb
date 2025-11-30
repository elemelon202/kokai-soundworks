class SavedController < ApplicationController
  before_action :authenticate_user!
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped

  def index
    @saved_musicians = current_user.saved_musicians
    @saved_bands = current_user.saved_bands
  end
end
