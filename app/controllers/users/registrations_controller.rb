class Users::RegistrationsController < Devise::RegistrationsController
  # Ensure the :user_type, :username, and :profile_picture_url parameters are allowed
  before_action :configure_sign_up_params, only: [:create]

  def create
    build_resource(sign_up_params)

    if resource.save
      if resource.active_for_authentication?
        set_flash_message! :notice, :signed_up
        sign_up(resource_name, resource)

        # 1. Create Profile Skeleton based on Type (Musician needs one immediately)
        create_profile_for(resource)

        # 2. Redirect based on the chosen role
        respond_with resource, location: after_sign_up_path_for(resource)
      else
        set_flash_message! :notice, :"signed_up_but_#{resource.inactive_message}"
        expire_data_after_sign_in!
        respond_with resource, location: after_inactive_sign_up_path_for(resource)
      end
    else
      clean_up_passwords resource
      set_minimum_password_length
      respond_with resource
    end
  end

  protected

  def configure_sign_up_params
    # CRITICAL: Allow user_type, username, and profile_picture_url to be passed from the form
    devise_parameter_sanitizer.permit(:sign_up, keys: [:user_type, :profile_picture_url, :username])
  end

  def after_sign_up_path_for(resource)
    case resource.user_type
    when 'band_leader'
      # Band leader redirects to create their first band
      new_band_path
    when 'venue'
      # Venue owner redirects to create their first venue
      venues_path
    when 'musician'
      # Musician redirects to edit their profile (which was just created below)
      edit_musician_path(resource.musician)
    else
      root_path
    end
  end

  private

  def create_profile_for(user)
    # The 'musician' role needs an associated Musician profile immediately after user creation.
    if user.user_type == 'musician'
      # The `user.username` is used as a default name for the new musician profile
      Musician.create!(user: user, name: user.username || "New Musician")
    end
    # Note: 'band' and 'venue_owner' create their associated records later via their respective `new` actions.
  end
end
