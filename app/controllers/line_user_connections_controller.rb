class LineUserConnectionsController < ApplicationController
  skip_after_action :verify_authorized

  def create
    # Check if user already has a connection
    existing = current_user.line_user_connection

    if existing&.linked?
      redirect_to edit_musician_path(current_user.musician), alert: "Your LINE account is already connected."
      return
    end

    if existing&.pending?
      redirect_to edit_musician_path(current_user.musician), notice: "You already have a pending link code: #{existing.link_code}"
      return
    end

    @connection = current_user.build_line_user_connection

    if @connection.save
      redirect_to edit_musician_path(current_user.musician), notice: "LINE link code generated!"
    else
      redirect_to edit_musician_path(current_user.musician), alert: "Failed to generate link code."
    end
  end

  def destroy
    connection = current_user.line_user_connection

    if connection&.destroy
      redirect_to edit_musician_path(current_user.musician), notice: "LINE account disconnected."
    else
      redirect_to edit_musician_path(current_user.musician), alert: "Failed to disconnect LINE account."
    end
  end
end
