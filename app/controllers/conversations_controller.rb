class ConversationsController < ApplicationController

  before_action(only: %i(show)) do
    if request.format.html?
      if params[:screen_name]
        case params[:type]
          when 'replying' then redirect_to(replying_path(screen_name: params[:screen_name]), status: 301)
          when 'replied' then redirect_to(replied_path(screen_name: params[:screen_name]), status: 301)
          when 'replying_and_replied' then redirect_to(replying_and_replied_path(screen_name: params[:screen_name]), status: 301)
          else redirect_to(root_path, status: 301)
        end
        logger.info "#{controller_name}##{action_name} redirect for backward compatibility"
      end
    else
      head :not_found
    end
  end
end
