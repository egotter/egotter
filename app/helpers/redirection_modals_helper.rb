module RedirectionModalsHelper
  def redirection_modal_page_name
    case controller_name
    when 'close_friends'
      t('modal.redirection_modal.page_names.close_friends')
    when 'unfriends'
      t('modal.redirection_modal.page_names.unfriends')
    when 'inactive_friends'
      t('modal.redirection_modal.page_names.inactive_friends')
    when 'one_sided_friends'
      t('modal.redirection_modal.page_names.one_sided_friends')
    when 'clusters'
      t('modal.redirection_modal.page_names.clusters')
    when 'delete_tweets'
      t('modal.redirection_modal.page_names.delete_tweets')
    when 'delete_favorites'
      t('modal.redirection_modal.page_names.delete_favorites')
    when 'tokimeki_unfollow'
      t('modal.redirection_modal.page_names.tokimeki_unfollow')
    when 'personality_insights'
      t('modal.redirection_modal.page_names.personality_insights')
    else
      t('modal.redirection_modal.page_names.default')
    end
  end
end
