class BandMainstageController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index, :past_winners]
  before_action :set_contest, only: [:index, :vote]

  def index
    @leaderboard = @contest.leaderboard(20)
    @user_vote = @contest.vote_for(current_user) if current_user
    skip_authorization
    skip_policy_scope
  end

  def vote
    skip_authorization

    if @contest.voted_by?(current_user)
      redirect_to band_mainstage_path, alert: "You've already voted this week!"
      return
    end

    band = Band.find(params[:band_id])
    vote = @contest.band_mainstage_votes.build(user: current_user, band: band)

    if vote.save
      respond_to do |format|
        format.html { redirect_to band_mainstage_path, notice: "Vote cast for #{band.name}!" }
        format.turbo_stream {
          render turbo_stream: turbo_stream.replace("band-mainstage-leaderboard", partial: "band_mainstage/leaderboard", locals: { contest: @contest, leaderboard: @contest.leaderboard(20), user_vote: band })
        }
      end
    else
      redirect_to band_mainstage_path, alert: vote.errors.full_messages.join(", ")
    end
  end

  def past_winners
    @winners = BandMainstageWinner.includes(:band, :band_mainstage_contest).recent.limit(52)
    skip_authorization
    skip_policy_scope
  end

  private

  def set_contest
    @contest = BandMainstageContest.current_contest
  end
end
