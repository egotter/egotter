module AdsenseHelper
  AD_NG_UIDS = [740700661939994624, 2412435452]

  def ad_ng_twitter_user?(twitter_user)
    if twitter_user.nil?
      false
    else
      AD_NG_UIDS.include? twitter_user.uid
    end
  end

  USER_TOP            = 1499207213
  USER_RESULT_TOP     = 2975940411
  USER_RESULT_BOTTOM  = 4452673613
  USER_OTHERS         = 8405195212
  USER_RIGHT          = 8092612016
  USER_WAITING        = 2340125210

  USER_HOME                  = 8784049177
  USER_TIMELINES_TOP         = 8209334100
  USER_TIMELINES_BOTTOM      = 6513765598
  USER_BLOCKING_OR_BLOCKED   = 2652565728
  USER_CLOSE_FRIENDS         = 9760899557
  USER_CLUSTERS              = 3003919518
  USER_COMMON_FOLLOWERS      = 6560021147
  USER_COMMON_FRIENDS        = 8643259000
  USER_COMMON_MUTUAL_FRIENDS = 5423388662
  USER_FAVORITE_FRIENDS      = 4512442302
  USER_FOLLOWERS             = 5818796876
  USER_FRIENDS               = 3937727232
  USER_INACTIVE_FOLLOWERS    = 1036231721
  USER_INACTIVE_FRIENDS      = 2330321466
  USER_ONE_SIDED_FOLLOWERS   = 9526941741
  USER_ONE_SIDED_FRIENDS     = 8022288381
  USER_REPLIED               = 9578256099
  USER_REPLYING              = 8180224575
  USER_STATUSES              = 5354750688
  USER_UNFOLLOWERS           = 2345443967
  USER_UNFRIENDS             = 4588463927
  USER_UPDATE_HISTORIES      = 4205320549
  USER_USAGE_STATS           = 1196013828

  GUEST_HOME                 = 1999805511
  GUEST_TIMELINES_TOP        = 7928943138
  GUEST_TIMELINES_BOTTOM     = 5364335453
  GUEST_TOP           = 4742208415
  GUEST_RESULT_TOP    = 6218941612
  GUEST_RESULT_BOTTOM = 7695674812
  GUEST_OTHERS        = 6928462015
  GUEST_RIGHT         = 8511414414
  GUEST_WAITING       = 9863392014

  def left_ad_slot(signed_in, controller, action, vertical)
    slot =
        case [signed_in, controller.to_s, action.to_s, vertical.to_sym]
        when [true,  'home',                  'new',  :top]    then USER_HOME
        when [true,  'timelines',             'show', :top]    then USER_TIMELINES_TOP
        when [true,  'timelines',             'show', :bottom] then USER_TIMELINES_BOTTOM
        when [true,  'waiting',               'new',  :top]    then USER_WAITING
        when [true,  'blocking_or_blocked',   'list', :slit]   then USER_BLOCKING_OR_BLOCKED
        when [true,  'blocking_or_blocked',   'show', :bottom] then USER_BLOCKING_OR_BLOCKED
        when [true,  'blocking_or_blocked',   'show', :top]    then USER_BLOCKING_OR_BLOCKED
        when [true,  'close_friends',         'list', :slit]   then USER_CLOSE_FRIENDS
        when [true,  'close_friends',         'show', :bottom] then USER_CLOSE_FRIENDS
        when [true,  'close_friends',         'show', :middle] then USER_CLOSE_FRIENDS
        when [true,  'close_friends',         'show', :top]    then USER_CLOSE_FRIENDS
        when [true,  'clusters',              'show', :top]    then USER_CLUSTERS
        when [true,  'common_followers',      'list', :slit]   then USER_COMMON_FOLLOWERS
        when [true,  'common_followers',      'show', :bottom] then USER_COMMON_FOLLOWERS
        when [true,  'common_followers',      'show', :middle] then USER_COMMON_FOLLOWERS
        when [true,  'common_followers',      'show', :top]    then USER_COMMON_FOLLOWERS
        when [true,  'common_friends',        'list', :slit]   then USER_COMMON_FRIENDS
        when [true,  'common_friends',        'show', :bottom] then USER_COMMON_FRIENDS
        when [true,  'common_friends',        'show', :middle] then USER_COMMON_FRIENDS
        when [true,  'common_friends',        'show', :top]    then USER_COMMON_FRIENDS
        when [true,  'common_mutual_friends', 'show', :bottom] then USER_COMMON_MUTUAL_FRIENDS
        when [true,  'common_mutual_friends', 'show', :middle] then USER_COMMON_MUTUAL_FRIENDS
        when [true,  'common_mutual_friends', 'show', :top]    then USER_COMMON_MUTUAL_FRIENDS
        when [true,  'favorite_friends',      'show', :bottom] then USER_FAVORITE_FRIENDS
        when [true,  'favorite_friends',      'show', :middle] then USER_FAVORITE_FRIENDS
        when [true,  'favorite_friends',      'show', :top]    then USER_FAVORITE_FRIENDS
        when [true,  'followers',             'show', :bottom] then USER_FOLLOWERS
        when [true,  'followers',             'show', :middle] then USER_FOLLOWERS
        when [true,  'followers',             'show', :top]    then USER_FOLLOWERS
        when [true,  'friends',               'new',  :top]    then USER_FRIENDS
        when [true,  'friends',               'show', :bottom] then USER_FRIENDS
        when [true,  'friends',               'show', :middle] then USER_FRIENDS
        when [true,  'friends',               'show', :top]    then USER_FRIENDS
        when [true,  'inactive_followers',    'show', :bottom] then USER_INACTIVE_FOLLOWERS
        when [true,  'inactive_followers',    'show', :middle] then USER_INACTIVE_FOLLOWERS
        when [true,  'inactive_followers',    'show', :top]    then USER_INACTIVE_FOLLOWERS
        when [true,  'inactive_friends',      'new',  :top]    then USER_INACTIVE_FRIENDS
        when [true,  'inactive_friends',      'show', :bottom] then USER_INACTIVE_FRIENDS
        when [true,  'inactive_friends',      'show', :middle] then USER_INACTIVE_FRIENDS
        when [true,  'inactive_friends',      'show', :top]    then USER_INACTIVE_FRIENDS
        when [true,  'one_sided_followers',   'show', :bottom] then USER_ONE_SIDED_FOLLOWERS
        when [true,  'one_sided_followers',   'show', :middle] then USER_ONE_SIDED_FOLLOWERS
        when [true,  'one_sided_followers',   'show', :top]    then USER_ONE_SIDED_FOLLOWERS
        when [true,  'one_sided_friends',     'new',  :top]    then USER_ONE_SIDED_FRIENDS
        when [true,  'one_sided_friends',     'show', :bottom] then USER_ONE_SIDED_FRIENDS
        when [true,  'one_sided_friends',     'show', :middle] then USER_ONE_SIDED_FRIENDS
        when [true,  'one_sided_friends',     'show', :top]    then USER_ONE_SIDED_FRIENDS
        when [true,  'replied',               'show', :bottom] then USER_REPLIED
        when [true,  'replied',               'show', :middle] then USER_REPLIED
        when [true,  'replied',               'show', :top]    then USER_REPLIED
        when [true,  'replying',              'show', :bottom] then USER_REPLYING
        when [true,  'replying',              'show', :middle] then USER_REPLYING
        when [true,  'replying',              'show', :top]    then USER_REPLYING
        when [true,  'statuses',              'show', :top]    then USER_UNFOLLOWERS
        when [true,  'unfollowers',           'list', :slit]   then USER_UNFOLLOWERS
        when [true,  'unfollowers',           'show', :bottom] then USER_UNFOLLOWERS
        when [true,  'unfollowers',           'show', :top]    then USER_UNFOLLOWERS
        when [true,  'unfriends',             'list', :slit]   then USER_UNFRIENDS
        when [true,  'unfriends',             'new',  :top]    then USER_UNFRIENDS
        when [true,  'unfriends',             'show', :bottom] then USER_UNFRIENDS
        when [true,  'unfriends',             'show', :top]    then USER_UNFRIENDS
        when [true,  'update_histories',      'show', :bottom] then USER_UPDATE_HISTORIES
        when [true,  'update_histories',      'show', :top]    then USER_UPDATE_HISTORIES
        when [true,  'usage_stats',           'show', :bottom] then USER_USAGE_STATS
        when [true,  'usage_stats',           'show', :middle] then USER_USAGE_STATS
        when [true,  'usage_stats',           'show', :top]    then USER_USAGE_STATS
        when [false, 'home',                  'new',  :top]    then GUEST_HOME
        when [false, 'timelines',             'show', :top]    then GUEST_TIMELINES_TOP
        when [false, 'timelines',             'show', :bottom] then GUEST_TIMELINES_BOTTOM
        when [false, 'waiting',               'new',  :top]    then GUEST_WAITING
        else nil
        end

    if slot
      slot
    else
      logger.info "#{__method__}: Not classified adsense #{signed_in} #{controller} #{action} #{vertical} #{request.original_fullpath}"
      signed_in ? USER_OTHERS : GUEST_OTHERS
    end
  end

  def right_ad_slot(signed_in)
    signed_in ? USER_RIGHT : GUEST_RIGHT
  end

  GUEST_TOP_TOP_RESP              = 1384769219
  GUEST_CLOSE_FRIENDS_TOP_RESP    = 1105567611
  GUEST_CLOSE_FRIENDS_SLIT_RESP   = 3919433211
  GUEST_CLOSE_FRIENDS_BOTTOM_RESP = 2582300812
  GUEST_REMOVED_TOP_RESP          = 4059034018
  GUEST_REMOVED_SLIT_RESP         = 5396166411
  GUEST_REMOVED_BOTTOM_RESP       = 7012500419
  GUEST_WAITING_RESP              = 9407563612
  GUEST_OTHERS_RESP               = 8070431219

  GUEST_HOME_RESP                 = 6274092442
  GUEST_TIMELINES_TOP_RESP        = 6629315666
  GUEST_TIMELINES_BOTTOM_RESP     = 1185417297

  USER_TOP_TOP_RESP               = 6872899613
  USER_CLOSE_FRIENDS_TOP_RESP     = 8210032018
  USER_CLOSE_FRIENDS_SLIT_RESP    = 9686765218
  USER_CLOSE_FRIENDS_BOTTOM_RESP  = 2163498414
  USER_REMOVED_TOP_RESP           = 3640231616
  USER_REMOVED_SLIT_RESP          = 5116964815
  USER_REMOVED_BOTTOM_RESP        = 6593698015
  USER_WAITING_RESP               = 7930830419
  USER_OTHERS_RESP                = 3500630816

  USER_HOME_RESP                  = 2721860243
  USER_TIMELINES_TOP_RESP         = 3564168622
  USER_TIMELINES_BOTTOM_RESP      = 9147011257
  USER_BLOCKING_OR_BLOCKED_RESP   = 4128464773
  USER_CLOSE_FRIENDS_RESP         = 1523672104
  USER_CLUSTERS_RESP              = 8444303677
  USER_COMMON_FOLLOWERS_RESP      = 2808833610
  USER_COMMON_FRIENDS_RESP        = 1430983397
  USER_COMMON_MUTUAL_FRIENDS_RESP = 3674003352
  USER_FAVORITE_FRIENDS_RESP      = 1910684917
  USER_FOLLOWERS_RESP             = 1594634923
  USER_FRIENDS_RESP               = 7585328204
  USER_INACTIVE_FOLLOWERS_RESP    = 7202184827
  USER_INACTIVE_FRIENDS_RESP      = 5466786547
  USER_ONE_SIDED_FOLLOWERS_RESP   = 2425690232
  USER_ONE_SIDED_FRIENDS_RESP     = 9346321801
  USER_REPLIED_RESP               = 5230627600
  USER_REPLYING_RESP              = 3725974245
  USER_STATUSES_RESP              = 8403585859
  USER_UNFOLLOWERS_RESP           = 2768115790
  USER_UNFRIENDS_RESP             = 5925951541
  USER_UPDATE_HISTORIES_RESP      = 3332234330
  USER_USAGE_STATS_RESP           = 7385183503

  def left_ad_slot_responsive(vertical_position)
    slot =
        case [user_signed_in?, controller_name.to_s, action_name.to_s, vertical_position.to_sym]
        when [true,  'home',                  'new',  :top]    then USER_HOME_RESP
        when [true,  'timelines',             'show', :top]    then USER_TIMELINES_TOP_RESP
        when [true,  'timelines',             'show', :bottom] then USER_TIMELINES_BOTTOM_RESP
        when [true,  'waiting',               'new',  :top]    then USER_WAITING_RESP
        when [true,  'blocking_or_blocked',   'list', :slit]   then USER_BLOCKING_OR_BLOCKED_RESP
        when [true,  'blocking_or_blocked',   'show', :bottom] then USER_BLOCKING_OR_BLOCKED_RESP
        when [true,  'blocking_or_blocked',   'show', :top]    then USER_BLOCKING_OR_BLOCKED_RESP
        when [true,  'close_friends',         'list', :slit]   then USER_CLOSE_FRIENDS_RESP
        when [true,  'close_friends',         'show', :bottom] then USER_CLOSE_FRIENDS_RESP
        when [true,  'close_friends',         'show', :middle] then USER_CLOSE_FRIENDS_RESP
        when [true,  'close_friends',         'show', :top]    then USER_CLOSE_FRIENDS_RESP
        when [true,  'clusters',              'show', :top]    then USER_CLUSTERS_RESP
        when [true,  'common_followers',      'list', :slit]   then USER_COMMON_FOLLOWERS_RESP
        when [true,  'common_followers',      'show', :bottom] then USER_COMMON_FOLLOWERS_RESP
        when [true,  'common_followers',      'show', :middle] then USER_COMMON_FOLLOWERS_RESP
        when [true,  'common_followers',      'show', :top]    then USER_COMMON_FOLLOWERS_RESP
        when [true,  'common_friends',        'list', :slit]   then USER_COMMON_FRIENDS_RESP
        when [true,  'common_friends',        'show', :bottom] then USER_COMMON_FRIENDS_RESP
        when [true,  'common_friends',        'show', :middle] then USER_COMMON_FRIENDS_RESP
        when [true,  'common_friends',        'show', :top]    then USER_COMMON_FRIENDS_RESP
        when [true,  'common_mutual_friends', 'show', :bottom] then USER_COMMON_MUTUAL_FRIENDS_RESP
        when [true,  'common_mutual_friends', 'show', :middle] then USER_COMMON_MUTUAL_FRIENDS_RESP
        when [true,  'common_mutual_friends', 'show', :top]    then USER_COMMON_MUTUAL_FRIENDS_RESP
        when [true,  'favorite_friends',      'show', :bottom] then USER_FAVORITE_FRIENDS_RESP
        when [true,  'favorite_friends',      'show', :middle] then USER_FAVORITE_FRIENDS_RESP
        when [true,  'favorite_friends',      'show', :top]    then USER_FAVORITE_FRIENDS_RESP
        when [true,  'followers',             'show', :bottom] then USER_FOLLOWERS_RESP
        when [true,  'followers',             'show', :middle] then USER_FOLLOWERS_RESP
        when [true,  'followers',             'show', :top]    then USER_FOLLOWERS_RESP
        when [true,  'friends',               'new',  :top]    then USER_FRIENDS_RESP
        when [true,  'friends',               'show', :bottom] then USER_FRIENDS_RESP
        when [true,  'friends',               'show', :middle] then USER_FRIENDS_RESP
        when [true,  'friends',               'show', :top]    then USER_FRIENDS_RESP
        when [true,  'inactive_followers',    'show', :bottom] then USER_INACTIVE_FOLLOWERS_RESP
        when [true,  'inactive_followers',    'show', :middle] then USER_INACTIVE_FOLLOWERS_RESP
        when [true,  'inactive_followers',    'show', :top]    then USER_INACTIVE_FOLLOWERS_RESP
        when [true,  'inactive_friends',      'new',  :top]    then USER_INACTIVE_FRIENDS_RESP
        when [true,  'inactive_friends',      'show', :bottom] then USER_INACTIVE_FRIENDS_RESP
        when [true,  'inactive_friends',      'show', :middle] then USER_INACTIVE_FRIENDS_RESP
        when [true,  'inactive_friends',      'show', :top]    then USER_INACTIVE_FRIENDS_RESP
        when [true,  'one_sided_followers',   'show', :bottom] then USER_ONE_SIDED_FOLLOWERS_RESP
        when [true,  'one_sided_followers',   'show', :middle] then USER_ONE_SIDED_FOLLOWERS_RESP
        when [true,  'one_sided_followers',   'show', :top]    then USER_ONE_SIDED_FOLLOWERS_RESP
        when [true,  'one_sided_friends',     'new',  :top]    then USER_ONE_SIDED_FRIENDS_RESP
        when [true,  'one_sided_friends',     'show', :bottom] then USER_ONE_SIDED_FRIENDS_RESP
        when [true,  'one_sided_friends',     'show', :middle] then USER_ONE_SIDED_FRIENDS_RESP
        when [true,  'one_sided_friends',     'show', :top]    then USER_ONE_SIDED_FRIENDS_RESP
        when [true,  'replied',               'show', :bottom] then USER_REPLIED_RESP
        when [true,  'replied',               'show', :middle] then USER_REPLIED_RESP
        when [true,  'replied',               'show', :top]    then USER_REPLIED_RESP
        when [true,  'replying',              'show', :bottom] then USER_REPLYING_RESP
        when [true,  'replying',              'show', :middle] then USER_REPLYING_RESP
        when [true,  'replying',              'show', :top]    then USER_REPLYING_RESP
        when [true,  'statuses',              'show', :top]    then USER_STATUSES_RESP
        when [true,  'unfollowers',           'list', :slit]   then USER_UNFOLLOWERS_RESP
        when [true,  'unfollowers',           'show', :bottom] then USER_UNFOLLOWERS_RESP
        when [true,  'unfollowers',           'show', :top]    then USER_UNFOLLOWERS_RESP
        when [true,  'unfriends',             'list', :slit]   then USER_UNFRIENDS_RESP
        when [true,  'unfriends',             'new',  :top]    then USER_UNFRIENDS_RESP
        when [true,  'unfriends',             'show', :bottom] then USER_UNFRIENDS_RESP
        when [true,  'unfriends',             'show', :top]    then USER_UNFRIENDS_RESP
        when [true,  'update_histories',      'show', :bottom] then USER_UPDATE_HISTORIES_RESP
        when [true,  'update_histories',      'show', :top]    then USER_UPDATE_HISTORIES_RESP
        when [true,  'usage_stats',           'show', :bottom] then USER_USAGE_STATS_RESP
        when [true,  'usage_stats',           'show', :middle] then USER_USAGE_STATS_RESP
        when [true,  'usage_stats',           'show', :top]    then USER_USAGE_STATS_RESP
        when [false, 'home',                  'new',  :top]    then GUEST_HOME_RESP
        when [false, 'timelines',             'show', :top]    then GUEST_TIMELINES_TOP_RESP
        when [false, 'timelines',             'show', :bottom] then GUEST_TIMELINES_BOTTOM_RESP
        when [false, 'waiting',               'new',  :top]    then GUEST_WAITING_RESP
        else nil
        end

    if slot
      slot
    else
      logger.info "#{__method__}: Not classified adsense #{user_signed_in?} #{controller_name} #{action_name} #{vertical_position} #{request.original_fullpath}"
      user_signed_in? ? USER_OTHERS_RESP : GUEST_OTHERS_RESP
    end
  end

  def async_adsense_wrapper_id
    "async-adsense-#{SecureRandom.urlsafe_base64(10)}"
  end
end
