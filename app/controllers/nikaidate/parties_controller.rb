class Nikaidate::PartiesController < ApplicationController

  def show
    @user = Nikaidate::Party.find_by(uid: params[:uid])
    @posts = Nikaidate::Post.where(archive_id: @user.opinions.map { |o| o.posts.pluck(:archive_id) }.flatten.uniq)
  end
end
