class SortOrder
  VALUES = [
      [I18n.t('sort.desc'), 'desc'],
      [I18n.t('sort.asc'), 'asc'],
      [I18n.t('sort.friends.desc'), 'friends_desc'],
      [I18n.t('sort.friends.asc'), 'friends_asc'],
      [I18n.t('sort.followers.desc'), 'followers_desc'],
      [I18n.t('sort.followers.asc'), 'followers_asc'],
  ]

  def initialize(value)
    @value = VALUES.map { |o| o[1] }.include?(value) ? value : VALUES[0][1]
  end

  def apply!(users)
    case @value
    when VALUES[1][1] then users.reverse!
    when VALUES[2][1] then users.sort_by!{|u| -u.friends_count}
    when VALUES[3][1] then users.sort_by!{|u| u.friends_count}
    when VALUES[4][1] then users.sort_by!{|u| -u.followers_count}
    when VALUES[5][1] then users.sort_by!{|u| u.followers_count}
    end
  end

  def default_order?
    @value == VALUES[0][1]
  end
end
