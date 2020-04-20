require 'active_support/concern'

module Concerns::FriendsConcern
  extend ActiveSupport::Concern

  included do

  end

  def initialize_instance_variables
    singular_name = controller_name.singularize

    @api_path = send("api_v1_#{controller_name}_list_path")
    if action_name == 'show'
      @breadcrumb_name = singular_name.to_sym
      @canonical_url = send("#{singular_name}_url", @twitter_user)
    else
      @breadcrumb_name = "all_#{controller_name}".to_sym
      @canonical_url = send("all_#{controller_name}_url", @twitter_user)
    end
    @page_title = t('.page_title', user: @twitter_user.mention_name)
    @content_title = t('.content_title', user: @twitter_user.mention_name)

    counts = related_counts

    @meta_title = t('.meta_title', {user: @twitter_user.mention_name}.merge(counts))
    @meta_description = t('.meta_description', {user: @twitter_user.mention_name}.merge(counts))

    default_description = t('.page_description', user: @twitter_user.screen_name)
    url = root_path_for(controller: controller_name)
    @page_description = t('.page_description_html', default: default_description, user: @twitter_user.screen_name, url: url)


    @tweet_text = t('.tweet_text', {user: @twitter_user.mention_name, url: @canonical_url}.merge(counts))

    @tabs = tabs
  end
end
