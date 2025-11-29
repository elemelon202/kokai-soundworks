class ShortCommentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_short
  before_action :set_comment, only: [:destroy]

  def create
    @comment = @short.short_comments.build(comment_params)
    @comment.user = current_user
    skip_authorization

    if @comment.save
      respond_to do |format|
        format.html { redirect_back fallback_location: discover_shorts_path }
        format.turbo_stream {
          render turbo_stream: turbo_stream.replace(
            "comments-section-#{@short.id}",
            partial: "musician_shorts/comments_section",
            locals: { short: @short }
          )
        }
      end
    else
      redirect_back fallback_location: discover_shorts_path, alert: "Comment couldn't be saved."
    end
  end

  def destroy
    skip_authorization

    if @comment.user == current_user
      @comment.destroy
      respond_to do |format|
        format.html { redirect_back fallback_location: discover_shorts_path }
        format.turbo_stream {
          render turbo_stream: turbo_stream.replace(
            "comments-section-#{@short.id}",
            partial: "musician_shorts/comments_section",
            locals: { short: @short }
          )
        }
      end
    else
      redirect_back fallback_location: discover_shorts_path, alert: "You can only delete your own comments."
    end
  end

  private

  def set_short
    @short = MusicianShort.find(params[:discover_short_id])
  end

  def set_comment
    @comment = @short.short_comments.find(params[:id])
  end

  def comment_params
    params.require(:short_comment).permit(:body)
  end
end
