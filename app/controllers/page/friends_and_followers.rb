class  Page::FriendsAndFollowers < ::Page::Base
  def all
    initialize_instance_variables
    @collection = @twitter_user.users_by(controller_name: controller_name)
  end

  def show
    initialize_instance_variables
  end

  private

  def initialize_instance_variables
    @api_path = send("api_v1_#{controller_name}_list_path")
    @breadcrumb_name, @canonical_url =
      if action_name == 'show'
        [controller_name.singularize.to_sym, send("#{controller_name.singularize}_url", @twitter_user)]
      else
        ["all_#{controller_name}".to_sym, send("all_#{controller_name}_url", @twitter_user)]
      end
    @page_title = t('.page_title', user: @twitter_user.mention_name)
    @content_title = t('.content_title', user: @twitter_user.mention_name)

    counts = related_counts

    @meta_title = t('.meta_title', {user: @twitter_user.mention_name}.merge(counts))

    @page_description = t('.page_description', user: @twitter_user.mention_name)
    @meta_description = t('.meta_description', {user: @twitter_user.mention_name}.merge(counts))

    @tweet_text = t('.tweet_text', {user: @twitter_user.mention_name, url: @canonical_url}.merge(counts))

    @tabs = tabs
  end
end
