class PostCommentsController < ApplicationController
  before_action :authenticate_user!

  def create
    @post = Post.find(params[:post_id])
    @comment = @post.post_comments.build(comment_params)
    @comment.user = current_user
    skip_authorization

    if @comment.save
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("post-#{@post.id}", partial: "posts/post", locals: { post: @post, comments_open: true }) }
        format.html { redirect_back fallback_location: posts_path }
      end
    else
      redirect_back fallback_location: posts_path, alert: "Comment can't be blank."
    end
  end

  def destroy
    @comment = PostComment.find(params[:id])
    @post = @comment.post
    skip_authorization

    if @comment.user == current_user || @post.user == current_user
      @comment.destroy
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("post-#{@post.id}", partial: "posts/post", locals: { post: @post, comments_open: true }) }
        format.html { redirect_back fallback_location: posts_path }
      end
    else
      redirect_back fallback_location: posts_path, alert: "You can't delete this comment."
    end
  end

  private

  def comment_params
    params.require(:post_comment).permit(:content)
  end
end
