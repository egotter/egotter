class ConversationsController < FriendsAndFollowers
  include Validation
  include SearchesHelper

  before_action(only: %i(show)) do
    if request.format.html?
      if valid_screen_name?(params[:screen_name])
        case params[:type]
          when 'replying' then redirect_to(replying_path(screen_name: params[:screen_name]), status: 301)
          when 'replied' then redirect_to(replied_path(screen_name: params[:screen_name]), status: 301)
          when 'replying_and_replied' then redirect_to(replying_and_replied_path(screen_name: params[:screen_name]), status: 301)
        end
      end
    else
      head :not_found
    end
  end

  before_action only: %i(new) do
    push_referer
    create_search_log
  end

  def new
  end

  def all
    super
    render template: 'friends/all' unless performed?
  end

  def show
    super
    @active_tab = 2
    render template: 'friends/show' unless performed?
  end
end
