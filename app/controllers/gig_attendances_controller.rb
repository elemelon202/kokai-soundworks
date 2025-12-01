class GigAttendancesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_gig

  def check_in
    attendance = current_user.gig_attendances.find_or_initialize_by(gig: @gig)

    if @gig.date == Date.current
      attendance.update(status: :attended)
      respond_to do |format|
        format.turbo_stream { render_turbo_stream }
        format.html { redirect_back fallback_location: venues_path, notice: "Checked in to #{@gig.name}!" }
      end
    else
      respond_to do |format|
        format.turbo_stream { render_turbo_stream }
        format.html { redirect_back fallback_location: venues_path, alert: "You can only check in on the day of the gig." }
      end
    end
  end

  def rsvp
    attendance = current_user.gig_attendances.find_or_initialize_by(gig: @gig)
    attendance.update(status: params[:status])

    respond_to do |format|
      format.turbo_stream { render_turbo_stream }
      format.html { redirect_back fallback_location: venues_path, notice: "RSVP updated!" }
    end
  end

  private

  def set_gig
    @gig = Gig.find(params[:gig_id])
  end

  def render_turbo_stream
    render turbo_stream: turbo_stream.replace(
      "gig-attendance-#{@gig.id}",
      partial: "gig_attendances/buttons",
      locals: { gig: @gig }
    )
  end
end
