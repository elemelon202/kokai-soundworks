class PostsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_post, only: [:show, :destroy]

  def index
    skip_authorization
    skip_policy_scope
    @posts = current_user.feed.includes(:user, :reposts, images_attachments: :blob, videos_attachments: :blob)
    @post = Post.new
  end

  def create
    @post = current_user.posts.build(post_params)
    skip_authorization

    if @post.save
      redirect_to posts_path, notice: "Post created!"
    else
      @posts = current_user.feed.includes(:user, :reposts)
      render :index, status: :unprocessable_entity
    end
  end

  def destroy
    skip_authorization
    if @post.user == current_user
      @post.destroy
      redirect_to posts_path, notice: "Post deleted."
    else
      redirect_to posts_path, alert: "You can't delete this post."
    end
  end

  def repost
    @post = Post.find(params[:id])
    skip_authorization

    existing = current_user.reposts.find_by(post: @post)
    if existing
      existing.destroy
    else
      current_user.reposts.create(post: @post)
    end

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace("post-#{@post.id}", partial: "posts/post", locals: { post: @post }) }
      format.html { redirect_back fallback_location: posts_path }
    end
  end

  def like
    @post = Post.find(params[:id])
    skip_authorization

    unless @post.liked_by?(current_user)
      current_user.post_likes.create(post: @post)
    end

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace("post-#{@post.id}", partial: "posts/post", locals: { post: @post }) }
      format.html { redirect_back fallback_location: posts_path }
    end
  end

  def unlike
    @post = Post.find(params[:id])
    skip_authorization

    like = current_user.post_likes.find_by(post: @post)
    like&.destroy

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace("post-#{@post.id}", partial: "posts/post", locals: { post: @post }) }
      format.html { redirect_back fallback_location: posts_path }
    end
  end

  private

  def set_post
    @post = Post.find(params[:id])
  end

  def post_params
    params.require(:post).permit(:content, images: [], videos: [])
  end
end
