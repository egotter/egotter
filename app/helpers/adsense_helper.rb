module AdsenseHelper
  AD_NG_UIDS = File.read(Rails.root.join('config/adult_ng_uids.txt')).split("\n").map(&:to_i)

  def ad_ng_page?
    delete_tweets = controller_name == 'delete_tweets' && action_name == 'show'
    delete_favorites = controller_name == 'delete_favorites' && action_name == 'show'
    pricing = controller_name == 'pricing'
    misc = controller_name == 'misc'
    suspicious = controller_name == 'error_pages' && action_name == 'suspicious_access_detected'
    locked = controller_name == 'error_pages' && action_name == 'account_locked'
    %w(login blockers settings).include?(controller_name) || delete_tweets || delete_favorites || pricing || misc || suspicious || locked
  end

  def ad_ng_user?(user)
    user && (ad_ng_uid?(user.uid) || ad_ng_name?(user) || ad_ng_description?(user) || ad_ng_location?(user))
  rescue => e
    Airbag.warn "#{__method__}: Unhandled exception #{e.inspect}"
    false
  end

  def ad_ng_uid?(uid)
    uid && AD_NG_UIDS.include?(uid)
  end

  def ad_ng_name?(user)
    ad_ng_text?(user.name)
  end

  def ad_ng_description?(user)
    ad_ng_text?(user.description)
  end

  def ad_ng_location?(user)
    ad_ng_text?(user.location)
  end

  def ad_ng_text?(text)
    text && text.match?(TwitterUserDecorator::ADULT_ACCOUNT_REGEXP)
  end

  USER_TOP            = 1499207213
  USER_RESULT_TOP     = 2975940411
  USER_RESULT_BOTTOM  = 4452673613
  USER_OTHERS         = 8405195212
  USER_RIGHT          = 8092612016
  USER_WAITING        = 2340125210

  USER_HOME                  = 8784049177 # 0247
  USER_TIMELINES_TOP         = 8209334100
  USER_TIMELINES_BOTTOM      = 6513765598
  USER_NOT_FOUND             = 5795444240
  USER_FORBIDDEN             = 6885643561
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
  USER_PROFILES              = 9008650779
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
  GUEST_UNFRIENDS     = 5075247378
  GUEST_OTHERS        = 6928462015
  GUEST_RIGHT         = 8511414414
  GUEST_WAITING       = 9863392014
  GUEST_PROFILES      = 2634814114

  RESPONSIVE_AD_IDS = [
      5788967123, # 0301
      6742315516, # 0302
      2002012770, # 0303
      9787281250, # 0304
      6619914631, # 0305
      5306832964, # 0306
      2680669624, # 0307
      3034170646, # 0308
      8474199583, # 0309
      9688931108, # 0310
      5848036246, # 0311
      8375849431, # 0312
      7741424618, # 0313
      8094925634, # 0314
      7010796875, # 0315
      4116152176, # 0316
      5585787146, # 0317
      3802179603, # 0318
      1390557110, # 0319
      1646542132, # 0320
      9077475443, # 0321
      5697715203, # 0322
      6335762031, # 0323
      7764393778, # 0324
      8020378796, # 0325
      6707297127, # 0326
      4436604425, # 0327
      3123522758, # 0328
      2489097937, # 0329
      8717742161, # 0330
      7404660497, # 0331
      6837043653, # 0332
      7844957271, # 0333
      1607933550, # 0334
      4210880319, # 0335
      5452501065, # 0336
      9235122967, # 0337
      4139419396, # 0338
      7922041298, # 0339
      3982796283, # 0340
      2832227414, # 0341
      7892982400, # 0342
      6579900737, # 0343
      3953737396, # 0344
      3057596301, # 0345
      1327574054, # 0346
      9014492380, # 0347
      5075247378, # 0348
      8675543043, # 0349
      2110134698, # 0350
      5397436411, # 0351 <- Next
      5014293031, # 0352
      6135803011, # 0353
      3509639678, # 0354
      7925071997, # 0355
      1359663648, # 0356
  ]

  def left_slot_pc_ad_id(controller, action, position)
    slot =
        case [user_signed_in?, controller.to_s, action.to_s, position.to_sym]
        when [true,  'home',                  'new',  :top]    then USER_HOME
        when [true,  'timelines',             'show', :bottom] then USER_TIMELINES_BOTTOM
        when [true,  'timelines',             'show', :feed_unfriends]        then 3123522758 # 0328
        when [true,  'timelines',             'show', :feed_unfollowers]      then 3123522758 # 0328
        when [true,  'timelines',             'show', :feed_mutual_unfriends] then 3123522758 # 0328
        when [true,  'timelines',             'show', :middle] then 5848036246 # 0311
        when [true,  'timelines',             'show', :top]    then 5788967123 # 0301
        when [true,  'not_found',             'show', :top]    then USER_NOT_FOUND
        when [true,  'forbidden',             'show', :top]    then USER_FORBIDDEN
        when [true,  'waiting',               'new',  :top]    then USER_WAITING
        when [true,  'mutual_unfriends',      'list', :slit]   then USER_BLOCKING_OR_BLOCKED
        when [true,  'mutual_unfriends',      'show', :bottom] then USER_BLOCKING_OR_BLOCKED
        when [true,  'mutual_unfriends',      'show', :middle] then USER_BLOCKING_OR_BLOCKED
        when [true,  'mutual_unfriends',      'show', :top]    then USER_BLOCKING_OR_BLOCKED
        when [true,  'close_friends',         'list', :slit]   then USER_CLOSE_FRIENDS
        when [true,  'close_friends',         'show', :bottom] then 4116152176 # 0316
        when [true,  'close_friends',         'show', :middle] then 5585787146 # 0317
        when [true,  'close_friends',         'show', :top]    then 7741424618 # 0313
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
        when [true,  'profiles',              'show', :top]    then 2002012770 # 0303
        when [true,  'profiles',              'show', :bottom] then 3982796283 # 0340
        when [true,  'replied',               'show', :bottom] then USER_REPLIED
        when [true,  'replied',               'show', :middle] then USER_REPLIED
        when [true,  'replied',               'show', :top]    then USER_REPLIED
        when [true,  'replying',              'show', :bottom] then USER_REPLYING
        when [true,  'replying',              'show', :middle] then USER_REPLYING
        when [true,  'replying',              'show', :top]    then USER_REPLYING
        when [true,  'statuses',              'show', :top]    then USER_UNFOLLOWERS
        when [true,  'unfollowers',           'list', :slit]   then USER_UNFOLLOWERS
        when [true,  'unfollowers',           'show', :bottom] then USER_UNFOLLOWERS
        when [true,  'unfollowers',           'show', :middle] then USER_UNFOLLOWERS
        when [true,  'unfollowers',           'show', :top]    then USER_UNFOLLOWERS
        when [true,  'unfriends',             'list', :slit]   then USER_UNFRIENDS
        when [true,  'unfriends',             'new',  :top]    then USER_UNFRIENDS
        when [true,  'unfriends',             'show', :bottom] then USER_UNFRIENDS
        when [true,  'unfriends',             'show', :middle] then USER_UNFRIENDS
        when [true,  'unfriends',             'show', :top]    then USER_UNFRIENDS
        when [true,  'update_histories',      'show', :bottom] then USER_UPDATE_HISTORIES
        when [true,  'update_histories',      'show', :top]    then USER_UPDATE_HISTORIES
        when [true,  'usage_stats',           'show', :bottom] then USER_USAGE_STATS
        when [true,  'usage_stats',           'show', :middle] then USER_USAGE_STATS
        when [true,  'usage_stats',           'show', :top]    then USER_USAGE_STATS
        when [true,  'access_confirmations',  'index', :top]   then 5452501065 # 0336
        when [true,  'access_confirmations',  'success', :top]   then 5452501065 # 0336
        when [true,  'follow_confirmations',  'index', :top]   then 3953737396 # 0344
        when [true,  'interval_confirmations','index', :top]   then 8675543043 # 0349

        when [false, 'home',                  'new',  :top]    then GUEST_HOME
        when [false, 'timelines',             'show', :bottom] then GUEST_TIMELINES_BOTTOM
        when [false, 'timelines',             'show', :feed_unfriends]        then 2489097937 # 0329
        when [false, 'timelines',             'show', :feed_unfollowers]      then 2489097937 # 0329
        when [false, 'timelines',             'show', :feed_mutual_unfriends] then 2489097937 # 0329
        when [false, 'timelines',             'show', :middle] then 8375849431 # 0312
        when [false, 'timelines',             'show', :top]    then 6742315516 # 0302
        when [false, 'waiting',               'new',  :top]    then GUEST_WAITING
        when [false, 'profiles',              'show', :top]    then 9787281250 # 0304
        when [false, 'profiles',              'show', :bottom] then 2832227414 # 0341
        when [false, 'unfollowers',           'list', :slit]   then 1646542132 # 0320
        when [false, 'unfollowers',           'show', :bottom] then 1646542132 # 0320
        when [false, 'unfollowers',           'show', :middle] then 1646542132 # 0320
        when [false, 'unfollowers',           'show', :top]    then 1646542132 # 0320
        when [false, 'unfriends',             'list', :slit]   then GUEST_UNFRIENDS
        when [false, 'unfriends',             'new',  :top]    then GUEST_UNFRIENDS
        when [false, 'unfriends',             'show', :bottom] then GUEST_UNFRIENDS
        when [false, 'unfriends',             'show', :middle] then GUEST_UNFRIENDS
        when [false, 'unfriends',             'show', :top]    then GUEST_UNFRIENDS
        when [false, 'mutual_unfriends',      'list', :slit]   then 7764393778 # 0324
        when [false, 'mutual_unfriends',      'show', :bottom] then 7764393778 # 0324
        when [false, 'mutual_unfriends',      'show', :middle] then 7764393778 # 0324
        when [false, 'mutual_unfriends',      'show', :top]    then 7764393778 # 0324
        when [false, 'close_friends',         'show', :bottom] then 6707297127 # 0326
        when [false, 'close_friends',         'show', :middle] then 4436604425 # 0327
        when [false, 'close_friends',         'show', :top]    then 8094925634 # 0314
        when [false, 'access_confirmations',  'index', :top]   then 5452501065 # 0336
        when [false, 'access_confirmations',  'success', :top]   then 5452501065 # 0336
        when [false, 'follow_confirmations',  'index', :top]   then 3953737396 # 0344
        when [false, 'interval_confirmations','index', :top]   then 8675543043 # 0349
        else nil
        end

    if controller == 'error_pages'
      slot = 4139419396
    elsif position.to_sym == :modal
      slot = 1327574054
    end

    if slot
      slot
    else
      Airbag.info "#{__method__}: Ad ID is not found", signed_in: user_signed_in?, controller: controller, action: action, position: position, fullpath: request.original_fullpath
      user_signed_in? ? USER_OTHERS : GUEST_OTHERS
    end
  end

  def right_slot_ad_id
    user_signed_in? ? USER_RIGHT : GUEST_RIGHT
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
  GUEST_TIMELINES_MIDDLE_RESP     = 6046113305
  GUEST_TIMELINES_BOTTOM_RESP     = 1185417297
  GUEST_TIMELINES_FEED_RESP       = 1607933550
  GUEST_NOT_FOUND_RESP            = 5567503094
  GUEST_FORBIDDEN_RESP            = 2749768065

  GUEST_AUDIENCE_INSIGHTS_RESP    = 3303210523
  GUEST_BLOCKING_OR_BLOCKED_RESP  = 8863848337
  GUEST_CLOSE_FRIENDS_RESP        = 5886331208
  GUEST_CLUSTERS_RESP             = 1747775648
  GUEST_FAVORITE_FRIENDS_RESP     = 7135833699
  GUEST_FOLLOWERS_RESP            = 9378853659
  GUEST_FRIENDS_RESP              = 5056465261
  GUEST_INACTIVE_FOLLOWERS_RESP   = 1387493623
  GUEST_INACTIVE_FRIENDS_RESP     = 7685308668
  GUEST_INACTIVE_MUTUAL_FRIENDS_RESP = 5359717591
  GUEST_MUTUAL_FRIENDS_RESP       = 9377664280
  GUEST_ONE_SIDED_FOLLOWERS_RESP  = 1755514503
  GUEST_ONE_SIDED_FRIENDS_RESP    = 9554113474
  GUEST_PROFILES_RESP             = 4714182547
  GUEST_REPLIED_RESP              = 4125337604
  GUEST_REPLYING_AND_REPLIED_RESP = 5169335276
  GUEST_REPLYING_RESP             = 9046491792
  GUEST_SCORES_RESP               = 1372371120
  GUEST_STATUSES_RESP             = 7746207785
  GUEST_UNFOLLOWERS_RESP          = 4730351572
  GUEST_UNFRIENDS_RESP            = 2302309413
  GUEST_UPDATE_HISTORIES_RESP     = 2898395159
  GUEST_USAGE_STATS_RESP          = 5985214186

  USER_TOP_TOP_RESP               = 6872899613
  USER_CLOSE_FRIENDS_TOP_RESP     = 8210032018
  USER_CLOSE_FRIENDS_SLIT_RESP    = 9686765218
  USER_CLOSE_FRIENDS_BOTTOM_RESP  = 2163498414
  USER_REMOVED_TOP_RESP           = 3640231616
  USER_REMOVED_SLIT_RESP          = 5116964815
  USER_REMOVED_BOTTOM_RESP        = 6593698015
  USER_WAITING_RESP               = 7930830419
  USER_OTHERS_RESP                = 3500630816

  USER_HOME_RESP                  = 2721860243 # 0224
  USER_TIMELINES_TOP_RESP         = 3564168622 # 0225
  USER_TIMELINES_MIDDLE_RESP      = 4253330115 # 0276
  USER_TIMELINES_BOTTOM_RESP      = 9147011257
  USER_TIMELINES_FEED_RESP        = 4210880319
  USER_NOT_FOUND_RESP             = 2206842589
  USER_FORBIDDEN_RESP             = 4641434232
  USER_AUDIENCE_INSIGHTS_RESP     = 8987971417
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
  USER_INACTIVE_MUTUAL_FRIENDS_RESP = 8552857148
  USER_MUTUAL_FRIENDS_RESP        = 7809431740
  USER_ONE_SIDED_FOLLOWERS_RESP   = 2425690232
  USER_ONE_SIDED_FRIENDS_RESP     = 9346321801
  USER_PROFILES_RESP              = 8650909191
  USER_REPLIED_RESP               = 5230627600
  USER_REPLYING_RESP              = 3725974245
  USER_REPLYING_AND_REPLIED_RESP  = 8305445130
  USER_SCORES_RESP                = 1216103231
  USER_STATUSES_RESP              = 8403585859
  USER_UNFOLLOWERS_RESP           = 2768115790 # 0217
  USER_UNFRIENDS_RESP             = 5925951541 # 0218
  USER_UPDATE_HISTORIES_RESP      = 3332234330
  USER_USAGE_STATS_RESP           = 7385183503

  def left_slot_responsive_ad_id(controller, action, position)
    slot =
        case [user_signed_in?, controller.to_s, action.to_s, position.to_sym]
        when [true,  'home',                  'new',  :top]    then USER_HOME_RESP
        when [true,  'timelines',             'show', :bottom] then USER_TIMELINES_BOTTOM_RESP
        when [true,  'timelines',             'show', :feed_unfriends]        then USER_TIMELINES_FEED_RESP
        when [true,  'timelines',             'show', :feed_unfollowers]      then USER_TIMELINES_FEED_RESP
        when [true,  'timelines',             'show', :feed_mutual_unfriends] then USER_TIMELINES_FEED_RESP
        when [true,  'timelines',             'show', :middle] then USER_TIMELINES_MIDDLE_RESP
        when [true,  'timelines',             'show', :top]    then USER_TIMELINES_TOP_RESP
        when [true,  'not_found',             'show', :top]    then USER_NOT_FOUND_RESP
        when [true,  'forbidden',             'show', :top]    then USER_FORBIDDEN_RESP
        when [true,  'waiting',               'new',  :top]    then USER_WAITING_RESP
        when [true,  'audience_insights',     'show', :bottom] then USER_AUDIENCE_INSIGHTS_RESP
        when [true,  'mutual_unfriends',      'list', :slit]   then USER_BLOCKING_OR_BLOCKED_RESP
        when [true,  'mutual_unfriends',      'show', :bottom] then USER_BLOCKING_OR_BLOCKED_RESP
        when [true,  'mutual_unfriends',      'show', :middle] then USER_BLOCKING_OR_BLOCKED_RESP
        when [true,  'mutual_unfriends',      'show', :top]    then USER_BLOCKING_OR_BLOCKED_RESP
        when [true,  'close_friends',         'list', :slit]   then USER_CLOSE_FRIENDS_RESP
        when [true,  'close_friends',         'show', :bottom] then USER_CLOSE_FRIENDS_RESP
        when [true,  'close_friends',         'show', :middle] then USER_CLOSE_FRIENDS_RESP
        when [true,  'close_friends',         'show', :top]    then USER_CLOSE_FRIENDS_RESP
        when [true,  'clusters',              'new',  :top]    then USER_CLUSTERS_RESP
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
        when [true,  'favorite_friends',      'list', :slit]   then USER_FAVORITE_FRIENDS_RESP
        when [true,  'favorite_friends',      'show', :bottom] then USER_FAVORITE_FRIENDS_RESP
        when [true,  'favorite_friends',      'show', :middle] then USER_FAVORITE_FRIENDS_RESP
        when [true,  'favorite_friends',      'show', :top]    then USER_FAVORITE_FRIENDS_RESP
        when [true,  'followers',             'list', :slit]   then USER_FOLLOWERS_RESP
        when [true,  'followers',             'show', :bottom] then USER_FOLLOWERS_RESP
        when [true,  'followers',             'show', :middle] then USER_FOLLOWERS_RESP
        when [true,  'followers',             'show', :top]    then USER_FOLLOWERS_RESP
        when [true,  'friends',               'list',  :slit]  then USER_FRIENDS_RESP
        when [true,  'friends',               'new',  :top]    then USER_FRIENDS_RESP
        when [true,  'friends',               'show', :bottom] then USER_FRIENDS_RESP
        when [true,  'friends',               'show', :middle] then USER_FRIENDS_RESP
        when [true,  'friends',               'show', :top]    then USER_FRIENDS_RESP
        when [true,  'inactive_followers',    'show', :bottom] then USER_INACTIVE_FOLLOWERS_RESP
        when [true,  'inactive_followers',    'show', :middle] then USER_INACTIVE_FOLLOWERS_RESP
        when [true,  'inactive_followers',    'show', :top]    then USER_INACTIVE_FOLLOWERS_RESP
        when [true,  'inactive_friends',      'list',  :list]  then USER_INACTIVE_FRIENDS_RESP
        when [true,  'inactive_friends',      'new',  :top]    then USER_INACTIVE_FRIENDS_RESP
        when [true,  'inactive_friends',      'show', :bottom] then USER_INACTIVE_FRIENDS_RESP
        when [true,  'inactive_friends',      'show', :middle] then USER_INACTIVE_FRIENDS_RESP
        when [true,  'inactive_friends',      'show', :top]    then USER_INACTIVE_FRIENDS_RESP
        when [true,  'inactive_mutual_friends','show',:bottom] then USER_INACTIVE_MUTUAL_FRIENDS_RESP
        when [true,  'inactive_mutual_friends','show',:middle] then USER_INACTIVE_MUTUAL_FRIENDS_RESP
        when [true,  'inactive_mutual_friends','show',:top]    then USER_INACTIVE_MUTUAL_FRIENDS_RESP
        when [true,  'mutual_friends',        'list', :slit]   then USER_MUTUAL_FRIENDS_RESP
        when [true,  'mutual_friends',        'show', :bottom] then USER_MUTUAL_FRIENDS_RESP
        when [true,  'mutual_friends',        'show', :middle] then USER_MUTUAL_FRIENDS_RESP
        when [true,  'mutual_friends',        'show', :top]    then USER_MUTUAL_FRIENDS_RESP
        when [true,  'one_sided_followers',   'list', :slit]   then USER_ONE_SIDED_FOLLOWERS_RESP
        when [true,  'one_sided_followers',   'show', :bottom] then USER_ONE_SIDED_FOLLOWERS_RESP
        when [true,  'one_sided_followers',   'show', :middle] then USER_ONE_SIDED_FOLLOWERS_RESP
        when [true,  'one_sided_followers',   'show', :top]    then USER_ONE_SIDED_FOLLOWERS_RESP
        when [true,  'one_sided_friends',     'list', :slit]   then USER_ONE_SIDED_FRIENDS_RESP
        when [true,  'one_sided_friends',     'new',  :top]    then USER_ONE_SIDED_FRIENDS_RESP
        when [true,  'one_sided_friends',     'show', :bottom] then USER_ONE_SIDED_FRIENDS_RESP
        when [true,  'one_sided_friends',     'show', :middle] then USER_ONE_SIDED_FRIENDS_RESP
        when [true,  'one_sided_friends',     'show', :top]    then USER_ONE_SIDED_FRIENDS_RESP
        when [true,  'profiles',              'show', :top]    then USER_PROFILES_RESP
        when [true,  'profiles',              'show', :bottom] then 7892982400 # 0342
        when [true,  'replied',               'list', :slit]   then USER_REPLIED_RESP
        when [true,  'replied',               'show', :bottom] then USER_REPLIED_RESP
        when [true,  'replied',               'show', :middle] then USER_REPLIED_RESP
        when [true,  'replied',               'show', :top]    then USER_REPLIED_RESP
        when [true,  'replying',              'list', :slit]   then USER_REPLYING_RESP
        when [true,  'replying',              'show', :bottom] then USER_REPLYING_RESP
        when [true,  'replying',              'show', :middle] then USER_REPLYING_RESP
        when [true,  'replying',              'show', :top]    then USER_REPLYING_RESP
        when [true,  'replying_and_replied',  'show', :bottom] then USER_REPLYING_AND_REPLIED_RESP
        when [true,  'replying_and_replied',  'show', :middle] then USER_REPLYING_AND_REPLIED_RESP
        when [true,  'replying_and_replied',  'show', :top]    then USER_REPLYING_AND_REPLIED_RESP
        when [true,  'scores',                'show', :bottom] then USER_SCORES_RESP
        when [true,  'scores',                'show', :middle] then USER_SCORES_RESP
        when [true,  'scores',                'show', :top]    then USER_SCORES_RESP
        when [true,  'statuses',              'show', :top]    then USER_STATUSES_RESP
        when [true,  'unfollowers',           'list', :slit]   then 8717742161 # 0330
        when [true,  'unfollowers',           'show', :bottom] then 8717742161 # 0330
        when [true,  'unfollowers',           'show', :middle] then 8717742161 # 0330
        when [true,  'unfollowers',           'show', :top]    then 8717742161 # 0330
        when [true,  'unfriends',             'list', :slit]   then USER_UNFRIENDS_RESP
        when [true,  'unfriends',             'new',  :top]    then USER_UNFRIENDS_RESP
        when [true,  'unfriends',             'show', :bottom] then USER_UNFRIENDS_RESP
        when [true,  'unfriends',             'show', :middle] then USER_UNFRIENDS_RESP
        when [true,  'unfriends',             'show', :top]    then USER_UNFRIENDS_RESP
        when [true,  'update_histories',      'show', :bottom] then USER_UPDATE_HISTORIES_RESP
        when [true,  'update_histories',      'show', :top]    then USER_UPDATE_HISTORIES_RESP
        when [true,  'usage_stats',           'show', :bottom] then USER_USAGE_STATS_RESP
        when [true,  'usage_stats',           'show', :middle] then USER_USAGE_STATS_RESP
        when [true,  'usage_stats',           'show', :top]    then USER_USAGE_STATS_RESP
        when [true,  'access_confirmations',  'index', :top]   then 9235122967 # 0337
        when [true,  'follow_confirmations',  'index', :top]   then 3057596301 # 0345
        when [true,  'interval_confirmations','index', :top]   then 2110134698 # 0350

        when [false, 'home',                  'new',  :top]    then GUEST_HOME_RESP
        when [false, 'timelines',             'show', :bottom] then GUEST_TIMELINES_BOTTOM_RESP
        when [false, 'timelines',             'show', :feed_unfriends]        then GUEST_TIMELINES_FEED_RESP
        when [false, 'timelines',             'show', :feed_unfollowers]      then GUEST_TIMELINES_FEED_RESP
        when [false, 'timelines',             'show', :feed_mutual_unfriends] then GUEST_TIMELINES_FEED_RESP
        when [false, 'timelines',             'show', :middle] then GUEST_TIMELINES_MIDDLE_RESP
        when [false, 'timelines',             'show', :top]    then GUEST_TIMELINES_TOP_RESP
        when [false, 'not_found',             'show', :top]    then GUEST_NOT_FOUND_RESP
        when [false, 'forbidden',             'show', :top]    then GUEST_FORBIDDEN_RESP
        when [false, 'waiting',               'new',  :top]    then GUEST_WAITING_RESP
        when [false, 'audience_insights',     'show', :bottom] then GUEST_AUDIENCE_INSIGHTS_RESP
        when [false, 'mutual_unfriends',      'list', :slit]   then GUEST_BLOCKING_OR_BLOCKED_RESP
        when [false, 'mutual_unfriends',      'show', :bottom] then GUEST_BLOCKING_OR_BLOCKED_RESP
        when [false, 'mutual_unfriends',      'show', :middle] then GUEST_BLOCKING_OR_BLOCKED_RESP
        when [false, 'mutual_unfriends',      'show', :top]    then GUEST_BLOCKING_OR_BLOCKED_RESP
        when [false, 'close_friends',         'list', :slit]   then GUEST_CLOSE_FRIENDS_RESP
        when [false, 'close_friends',         'show', :bottom] then GUEST_CLOSE_FRIENDS_RESP
        when [false, 'close_friends',         'show', :middle] then GUEST_CLOSE_FRIENDS_RESP
        when [false, 'close_friends',         'show', :top]    then GUEST_CLOSE_FRIENDS_RESP
        when [false, 'clusters',              'new',  :top]    then GUEST_CLUSTERS_RESP
        when [false, 'clusters',              'show', :top]    then GUEST_CLUSTERS_RESP
        when [false, 'favorite_friends',      'list', :slit]   then GUEST_FAVORITE_FRIENDS_RESP
        when [false, 'favorite_friends',      'show', :bottom] then GUEST_FAVORITE_FRIENDS_RESP
        when [false, 'favorite_friends',      'show', :middle] then GUEST_FAVORITE_FRIENDS_RESP
        when [false, 'favorite_friends',      'show', :top]    then GUEST_FAVORITE_FRIENDS_RESP
        when [false, 'followers',             'list', :slit]   then GUEST_FOLLOWERS_RESP
        when [false, 'followers',             'show', :bottom] then GUEST_FOLLOWERS_RESP
        when [false, 'followers',             'show', :middle] then GUEST_FOLLOWERS_RESP
        when [false, 'followers',             'show', :top]    then GUEST_FOLLOWERS_RESP
        when [false, 'friends',               'list', :slit]   then GUEST_FRIENDS_RESP
        when [false, 'friends',               'new',  :top]    then GUEST_FRIENDS_RESP
        when [false, 'friends',               'show', :bottom] then GUEST_FRIENDS_RESP
        when [false, 'friends',               'show', :middle] then GUEST_FRIENDS_RESP
        when [false, 'friends',               'show', :top]    then GUEST_FRIENDS_RESP
        when [false, 'inactive_followers',    'list', :slit]   then GUEST_INACTIVE_FOLLOWERS_RESP
        when [false, 'inactive_followers',    'show', :bottom] then GUEST_INACTIVE_FOLLOWERS_RESP
        when [false, 'inactive_followers',    'show', :middle] then GUEST_INACTIVE_FOLLOWERS_RESP
        when [false, 'inactive_followers',    'show', :top]    then GUEST_INACTIVE_FOLLOWERS_RESP
        when [false, 'inactive_friends',      'list', :slit]   then GUEST_INACTIVE_FRIENDS_RESP
        when [false, 'inactive_friends',      'new',  :top]    then GUEST_INACTIVE_FRIENDS_RESP
        when [false, 'inactive_friends',      'show', :bottom] then GUEST_INACTIVE_FRIENDS_RESP
        when [false, 'inactive_friends',      'show', :middle] then GUEST_INACTIVE_FRIENDS_RESP
        when [false, 'inactive_friends',      'show', :top]    then GUEST_INACTIVE_FRIENDS_RESP
        when [false, 'inactive_mutual_friends','show',:bottom] then GUEST_INACTIVE_MUTUAL_FRIENDS_RESP
        when [false, 'inactive_mutual_friends','show',:middle] then GUEST_INACTIVE_MUTUAL_FRIENDS_RESP
        when [false, 'inactive_mutual_friends','show',:top]    then GUEST_INACTIVE_MUTUAL_FRIENDS_RESP
        when [false, 'mutual_friends',        'list', :slit]   then GUEST_MUTUAL_FRIENDS_RESP
        when [false, 'mutual_friends',        'show', :bottom] then GUEST_MUTUAL_FRIENDS_RESP
        when [false, 'mutual_friends',        'show', :middle] then GUEST_MUTUAL_FRIENDS_RESP
        when [false, 'mutual_friends',        'show', :top]    then GUEST_MUTUAL_FRIENDS_RESP
        when [false, 'one_sided_followers',   'list', :slit]   then GUEST_ONE_SIDED_FOLLOWERS_RESP
        when [false, 'one_sided_followers',   'show', :bottom] then GUEST_ONE_SIDED_FOLLOWERS_RESP
        when [false, 'one_sided_followers',   'show', :middle] then GUEST_ONE_SIDED_FOLLOWERS_RESP
        when [false, 'one_sided_followers',   'show', :top]    then GUEST_ONE_SIDED_FOLLOWERS_RESP
        when [false, 'one_sided_friends',     'list', :slit]   then GUEST_ONE_SIDED_FRIENDS_RESP
        when [false, 'one_sided_friends',     'new',  :top]    then GUEST_ONE_SIDED_FRIENDS_RESP
        when [false, 'one_sided_friends',     'show', :bottom] then GUEST_ONE_SIDED_FRIENDS_RESP
        when [false, 'one_sided_friends',     'show', :middle] then GUEST_ONE_SIDED_FRIENDS_RESP
        when [false, 'one_sided_friends',     'show', :top]    then GUEST_ONE_SIDED_FRIENDS_RESP
        when [false, 'profiles',              'show', :top]    then GUEST_PROFILES_RESP
        when [false, 'profiles',              'show', :bottom] then 6579900737 # 0343
        when [false, 'replied',               'list', :slit]   then GUEST_REPLIED_RESP
        when [false, 'replied',               'show', :bottom] then GUEST_REPLIED_RESP
        when [false, 'replied',               'show', :middle] then GUEST_REPLIED_RESP
        when [false, 'replied',               'show', :top]    then GUEST_REPLIED_RESP
        when [false, 'replying',              'list', :slit]   then GUEST_REPLYING_RESP
        when [false, 'replying',              'show', :bottom] then GUEST_REPLYING_RESP
        when [false, 'replying',              'show', :middle] then GUEST_REPLYING_RESP
        when [false, 'replying',              'show', :top]    then GUEST_REPLYING_RESP
        when [false, 'replying_and_replied',  'show', :bottom] then GUEST_REPLYING_AND_REPLIED_RESP
        when [false, 'replying_and_replied',  'show', :middle] then GUEST_REPLYING_AND_REPLIED_RESP
        when [false, 'replying_and_replied',  'show', :top]    then GUEST_REPLYING_AND_REPLIED_RESP
        when [false, 'scores',                'show', :bottom] then GUEST_SCORES_RESP
        when [false, 'scores',                'show', :middle] then GUEST_SCORES_RESP
        when [false, 'scores',                'show', :top]    then GUEST_SCORES_RESP
        when [false, 'statuses',              'show', :top]    then GUEST_STATUSES_RESP
        when [false, 'unfollowers',           'list', :slit]   then GUEST_UNFOLLOWERS_RESP
        when [false, 'unfollowers',           'show', :bottom] then GUEST_UNFOLLOWERS_RESP
        when [false, 'unfollowers',           'show', :middle] then GUEST_UNFOLLOWERS_RESP
        when [false, 'unfollowers',           'show', :top]    then GUEST_UNFOLLOWERS_RESP
        when [false, 'unfriends',             'list', :slit]   then GUEST_UNFRIENDS_RESP
        when [false, 'unfriends',             'new',  :top]    then GUEST_UNFRIENDS_RESP
        when [false, 'unfriends',             'show', :bottom] then GUEST_UNFRIENDS_RESP
        when [false, 'unfriends',             'show', :middle] then GUEST_UNFRIENDS_RESP
        when [false, 'unfriends',             'show', :top]    then GUEST_UNFRIENDS_RESP
        when [false, 'update_histories',      'show', :bottom] then GUEST_UPDATE_HISTORIES_RESP
        when [false, 'update_histories',      'show', :top]    then GUEST_UPDATE_HISTORIES_RESP
        when [false, 'usage_stats',           'show', :bottom] then GUEST_USAGE_STATS_RESP
        when [false, 'usage_stats',           'show', :middle] then GUEST_USAGE_STATS_RESP
        when [false, 'usage_stats',           'show', :top]    then GUEST_USAGE_STATS_RESP
        when [false, 'access_confirmations',  'index', :top]   then 9235122967 # 0337
        when [false, 'follow_confirmations',  'index', :top]   then 3057596301 # 0345
        when [false, 'interval_confirmations','index', :top]   then 2110134698 # 0350
        else nil
        end

    if controller == 'error_pages'
      slot = 7922041298
    elsif position.to_sym == :modal
      slot = 9014492380
    end

    if slot
      slot
    else
      Airbag.info "#{__method__}: Ad ID is not found", signed_in: user_signed_in?, controller: controller, action: action, position: position, fullpath: request.original_fullpath
      user_signed_in? ? USER_OTHERS_RESP : GUEST_OTHERS_RESP
    end
  end

  def async_adsense_wrapper_id(vertical)
    @async_adsense_wrapper_rand ||= SecureRandom.urlsafe_base64(10)
    "async-adsense-#{vertical}-#{@async_adsense_wrapper_rand}"
  end

  def left_slot_ad_id(controller, action, vertical)
    if request.from_pc?
      left_slot_pc_ad_id(controller, action, vertical)
    else
      left_slot_responsive_ad_id(controller, action, vertical)
    end
  end
end
