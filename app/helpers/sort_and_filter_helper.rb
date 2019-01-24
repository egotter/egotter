module SortAndFilterHelper
  USERS_SORT_ORDERS = [
      [I18n.t('sort.desc'), 'desc'],
      [I18n.t('sort.asc'), 'asc'],
      [I18n.t('sort.friends.desc'), 'friends_desc'],
      [I18n.t('sort.friends.asc'), 'friends_asc'],
      [I18n.t('sort.followers.desc'), 'followers_desc'],
      [I18n.t('sort.followers.asc'), 'followers_asc'],
  ]

  USERS_FILTERS = [
      [I18n.t('filter.inactive'), 'inactive'],
  ]

  def users_sort_orders
    USERS_SORT_ORDERS
  end

  def users_filters
    USERS_FILTERS
  end
end
