class ScoresController < ApplicationController
  include Validation
  include Concerns::Logging
  include SearchesHelper
  include ScoresHelper

  before_action { valid_screen_name?(params[:screen_name]) }
  before_action { not_found_screen_name?(params[:screen_name]) }
  before_action { @tu = build_twitter_user(params[:screen_name]) }
  before_action { authorized_search?(@tu) }
  before_action { existing_uid?(@tu.uid.to_i) }
  before_action  do
    @twitter_user = TwitterUser.latest(@tu.uid.to_i)
    remove_instance_variable(:@tu)
  end
  before_action do
    push_referer
    create_search_log
  end

  def show
    @breadcrumb_name = controller_name.singularize.to_sym
    @canonical_url = send("#{controller_name.singularize}_url", screen_name: @twitter_user.screen_name)
    @page_title = t('.page_title', user: @twitter_user.mention_name)

    score = find_or_create_score(@twitter_user.uid)
    @score = score.klout_score.to_f
    will_win = score.will_win
    will_loose = score.will_loose

    @meta_description = t('.meta_description', user: @twitter_user.mention_name, score: (@score * 10000).round.to_s(:delimited))
    @page_description = t('.page_description', user: @twitter_user.mention_name)

    tweet_text = t('.score_text_html', user: @twitter_user.mention_name, score: (@score * 10000).round.to_s(:delimited))
    tweet_text += t('.will_win', users: will_win.map { |name| mention_name(name) }.join(' ')) if will_win.any?
    tweet_text += t('.will_loose', users: will_loose.map { |name| mention_name(name) }.join(' ')) if will_loose.any?
    @tweet_text =  tweet_text + "\n#egotter #{@canonical_url}"

    @screen_names = (will_win + will_loose).uniq

    @stat = UsageStat.find_by(uid: @twitter_user.uid)
  end
end
