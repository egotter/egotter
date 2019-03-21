class Nikaidate::RankingController < ApplicationController

  def top
    @users = Nikaidate::Party.order(rank: :asc)
    @year = params[:year].to_i
  end
end
