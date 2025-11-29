class MainstageController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index, :past_winners]
  before_action :set_contest, only: [:index, :vote]

  # Main leaderboard page
  def index
    @leaderboard = @contest.leaderboard(20)
    @user_vote = @contest.vote_for(current_user) if current_user
    skip_authorization
    skip_policy_scope
  end

  # Cast a vote
  def vote
    skip_authorization

    if @contest.voted_by?(current_user)
      redirect_to mainstage_path, alert: "You've already voted this week!"
      return
    end

    musician = Musician.find(params[:musician_id])
    vote = @contest.mainstage_votes.build(user: current_user, musician: musician)

    if vote.save
      respond_to do |format|
        format.html { redirect_to mainstage_path, notice: "Vote cast for #{musician.name}!" }
        format.turbo_stream {
          render turbo_stream: turbo_stream.replace("mainstage-leaderboard", partial: "mainstage/leaderboard", locals: { contest: @contest, leaderboard: @contest.leaderboard(20), user_vote: musician })
        }
      end
    else
      redirect_to mainstage_path, alert: vote.errors.full_messages.join(", ")
    end
  end

  # Archive of past winners
  def past_winners
    @winners = MainstageWinner.includes(:musician, :mainstage_contest).recent.limit(52)
    skip_authorization
    skip_policy_scope
  end

  private

  def set_contest
    @contest = MainstageContest.current_contest
  end
end
