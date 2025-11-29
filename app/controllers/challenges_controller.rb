class ChallengesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_challenge, only: [:show, :start_voting, :close, :pick_winner]
  before_action :require_musician, only: [:new, :create, :respond, :submit_response]
  skip_after_action :verify_authorized, only: [:index, :vote, :unvote]
  skip_after_action :verify_policy_scoped, except: [:index]

  def index
    @challenges = policy_scope(Challenge).includes(:creator, :original_short, :challenge_responses)
                                          .recent

    @open_challenges = policy_scope(Challenge).open.recent.limit(6)
    @voting_challenges = policy_scope(Challenge).voting.recent.limit(6)
  end

  def show
    authorize @challenge
    @responses = @challenge.challenge_responses
                           .includes(:musician, :musician_short)
                           .top_voted
    @user_response = @challenge.response_from(current_user.musician) if current_user.musician
  end

  def new
    @challenge = Challenge.new
    @challenge.original_short_id = params[:original_short_id] if params[:original_short_id]
    authorize @challenge
    @shorts = current_user.musician.musician_shorts
  end

  def create
    @challenge = Challenge.new(challenge_params)
    @challenge.creator = current_user.musician
    authorize @challenge

    if @challenge.save
      redirect_to @challenge, notice: "Challenge created! Others can now respond."
    else
      @shorts = current_user.musician.musician_shorts
      render :new, status: :unprocessable_entity
    end
  end

  # Page to submit a response to a challenge
  def respond
    @challenge = Challenge.find(params[:id])
    authorize @challenge
    @shorts = current_user.musician.musician_shorts

    if @challenge.responded_by?(current_user.musician)
      redirect_to @challenge, alert: "You've already responded to this challenge."
    end
  end

  # Submit a response
  def submit_response
    @challenge = Challenge.find(params[:id])
    authorize @challenge

    if @challenge.responded_by?(current_user.musician)
      redirect_to @challenge, alert: "You've already responded to this challenge."
      return
    end

    @response = @challenge.challenge_responses.build(
      musician: current_user.musician,
      musician_short_id: params[:musician_short_id]
    )

    if @response.save
      # Create notification for challenge creator
      Notification.create(
        user: @challenge.creator.user,
        notification_type: 'challenge_response',
        message: "#{current_user.musician.name} responded to your challenge \"#{@challenge.title}\"",
        notifiable: @response
      )
      redirect_to @challenge, notice: "Response submitted!"
    else
      @shorts = current_user.musician.musician_shorts
      render :respond, status: :unprocessable_entity
    end
  end

  # Vote for a response
  def vote
    @response = ChallengeResponse.find(params[:response_id])
    @challenge = @response.challenge

    if @response.voted_by?(current_user)
      redirect_to @challenge, alert: "You've already voted for this response."
      return
    end

    @vote = @response.challenge_votes.build(user: current_user)

    if @vote.save
      respond_to do |format|
        format.html { redirect_to @challenge, notice: "Vote recorded!" }
        format.turbo_stream
      end
    else
      redirect_to @challenge, alert: @vote.errors.full_messages.join(", ")
    end
  end

  # Unvote
  def unvote
    @response = ChallengeResponse.find(params[:response_id])
    @challenge = @response.challenge
    @vote = @response.challenge_votes.find_by(user: current_user)

    if @vote&.destroy
      respond_to do |format|
        format.html { redirect_to @challenge, notice: "Vote removed." }
        format.turbo_stream
      end
    else
      redirect_to @challenge, alert: "Could not remove vote."
    end
  end

  # Creator actions
  def start_voting
    authorize @challenge
    @challenge.start_voting!
    redirect_to @challenge, notice: "Voting has started!"
  end

  def close
    authorize @challenge
    @challenge.close_and_pick_winner!

    # Notify winner
    if @challenge.winner
      Notification.create(
        user: @challenge.winner.musician.user,
        notification_type: 'challenge_win',
        message: "You won the challenge \"#{@challenge.title}\"!",
        notifiable: @challenge
      )
    end

    redirect_to @challenge, notice: "Challenge closed. Winner announced!"
  end

  def pick_winner
    authorize @challenge
    response = @challenge.challenge_responses.find(params[:response_id])
    @challenge.pick_winner!(response)

    Notification.create(
      user: response.musician.user,
      notification_type: 'challenge_win',
      message: "You were selected as winner of \"#{@challenge.title}\"!",
      notifiable: @challenge
    )

    redirect_to @challenge, notice: "Winner selected!"
  end

  private

  def set_challenge
    @challenge = Challenge.find(params[:id])
  end

  def challenge_params
    params.require(:challenge).permit(:title, :description, :original_short_id)
  end

  def require_musician
    unless current_user.musician
      redirect_to new_musician_path, alert: "You need a musician profile to participate in challenges."
    end
  end
end
