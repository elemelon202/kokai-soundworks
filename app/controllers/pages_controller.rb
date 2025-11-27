class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :home ]
  skip_after_action :verify_authorized, only: [ :home ]
  skip_after_action :verify_policy_scoped, only: [ :home ], raise: false

  def home
  end
end
