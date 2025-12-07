class ApplicationController < ActionController::Base
  include Pagy::Backend
  before_action :authenticate_user!
  before_action :set_locale
  include Pundit::Authorization

  after_action :verify_authorized, except: :index, unless: :skip_pundit?, raise: false

  after_action :verify_policy_scoped, only: :index, unless: :skip_pundit?, raise: false

rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def set_locale
    I18n.locale = session[:locale] || I18n.default_locale
  end

  def skip_pundit?
    devise_controller? || params[:controller] =~ /(^(rails_)?admin)|(^pages$)/
  end

  def user_not_authorized
    flash[:alert] = "You are not authorized to perform that action."
    redirect_to(request.referrer || root_path)
  end
end
