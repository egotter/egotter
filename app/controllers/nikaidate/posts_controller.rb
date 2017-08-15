class Nikaidate::PostsController < ApplicationController

  def index
    @posts = Nikaidate::Post.all
  end

  def show
    @post = Nikaidate::Post.find_by(archive_id: params[:archive_id])
  end
end
