class ProtectionController < ApplicationController
  include Concerns::Showable

  def show
    @api_path = send("api_v1_#{controller_name}_list_path")
    @breadcrumb_name = controller_name.singularize.to_sym
    @canonical_url = send("#{controller_name.singularize}_url", @twitter_user)

    @page_title = t('.page_title', user: @twitter_user.mention_name)
    @meta_title = t('.meta_title', user: @twitter_user.mention_name)

    @page_description = t('.page_description', user: @twitter_user.mention_name)
    @meta_description = t('.meta_description', user: @twitter_user.mention_name)
  end
end
