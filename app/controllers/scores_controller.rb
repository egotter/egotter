class ScoresController < ApplicationController
  include Concerns::SearchRequestConcern
  include ScoresHelper

  def show
    @breadcrumb_name = controller_name.singularize.to_sym
    @canonical_url = send("#{controller_name.singularize}_url", @twitter_user)
    @page_title = t('.page_title', user: @twitter_user.mention_name)

    score = find_or_create_score(@twitter_user.uid)
    @score = score.klout_score.to_f
    will_win = score.will_win
    will_loose = score.will_loose

    @meta_description = t('.meta_description', user: @twitter_user.mention_name, score: (@score * 10000).round.to_s(:delimited))
    @page_description = t('.page_description', user: @twitter_user.mention_name)

    @tweet_text =  scores_text(@twitter_user, will_win, will_loose, @score, @canonical_url)

    @screen_names = (will_win + will_loose).uniq
  end

  private

  def scores_text(twitter_user, will_win, will_loose, score, canonical_url)
    tweet_text = t('.score_text_html', user: twitter_user.mention_name, score: (score * 10000).round.to_s(:delimited))
    tweet_text += t('.will_win', users: will_win.map { |name| mention_name(name) }.join(' ')) if will_win.any?
    tweet_text += t('.will_loose', users: will_loose.map { |name| mention_name(name) }.join(' ')) if will_loose.any?
    tweet_text + "\n#egotter #{canonical_url}"
  end

  def mention_name(screen_name)
    view_context.mention_name(screen_name)
  end
end
