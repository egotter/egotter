module AdsenseHelper
  NG_UIDS = [740700661939994624, 2412435452]

  def ad_ng_twitter_user?(twitter_user)
    if twitter_user.nil?
      false
    else
      NG_UIDS.include? twitter_user.uid.to_i
    end
  end

  GUEST_TOP           = 4742208415
  GUEST_RESULT_TOP    = 6218941612
  GUEST_RESULT_BOTTOM = 7695674812
  GUEST_OTHERS        = 6928462015
  GUEST_RIGHT         = 8511414414
  GUEST_WAITING       = 9863392014
  USER_TOP            = 1499207213
  USER_RESULT_TOP     = 2975940411
  USER_RESULT_BOTTOM  = 4452673613
  USER_OTHERS         = 8405195212
  USER_RIGHT          = 8092612016
  USER_WAITING        = 2340125210

  def left_ad_slot(signed_in, controller, action, vertical)
    slot =
      case [signed_in, controller.to_s, action.to_s, vertical.to_sym]
        when [true,  'home',      'new',                    :top]    then USER_TOP
        when [true,  'timelines', 'show',                   :top]    then USER_RESULT_TOP
        when [true,  'timelines', 'show',                   :bottom] then USER_RESULT_BOTTOM
        when [true,  '',          'show',                   :slit]   then '9958552019'
        when [true,  '',          'search_histories/index', :slit]   then '5378418414'
        when [true,  'waiting',   'new',                    :top]    then USER_WAITING
        when [false, 'home',      'new',                    :top]    then GUEST_TOP
        when [false, 'timelines', 'show',                   :top]    then GUEST_RESULT_TOP
        when [false, 'timelines', 'show',                   :bottom] then GUEST_RESULT_BOTTOM
        when [false, '',          'show',                   :slit]   then '5528352415'
        when [false, '',          'search_histories/index', :slit]   then '3901685219'
        when [false, 'waiting',   'new',                    :top]    then GUEST_WAITING
        else nil
      end

    if slot
      slot
    else
      logger.info "Not classified adsense: #{signed_in} #{controller} #{action} #{vertical} #{request.original_fullpath}"
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
  USER_TOP_TOP_RESP               = 6872899613
  USER_CLOSE_FRIENDS_TOP_RESP     = 8210032018
  USER_CLOSE_FRIENDS_SLIT_RESP    = 9686765218
  USER_CLOSE_FRIENDS_BOTTOM_RESP  = 2163498414
  USER_REMOVED_TOP_RESP           = 3640231616
  USER_REMOVED_SLIT_RESP          = 5116964815
  USER_REMOVED_BOTTOM_RESP        = 6593698015
  USER_WAITING_RESP               = 7930830419
  USER_OTHERS_RESP                = 3500630816

  def left_ad_slot_RESPonsive(vertical_position)
    slot =
      if %w(searches search_results).include?(controller_name)
        case [user_signed_in?, action_name, vertical_position]
          when [false, 'new',     :top]    then GUEST_TOP_TOP_RESP # 0101
          when [false, 'new',     :bottom] then '2861502412' # 0102
          when [false, 'show',    :top]    then '4338235610' # 0103
          when [false, 'show',    :middle] then '2442700011' # 0104
          when [false, 'show',    :bottom] then '5814968816' # 0105
          when [false, 'waiting', :top]    then GUEST_WAITING_RESP # 0147

          when [true,  'new',     :top]    then USER_TOP_TOP_RESP # 0151
          when [true,  'new',     :bottom] then '2303099214' # 0152
          when [true,  'show',    :top]    then '3779832415' # 0153
          when [true,  'show',    :middle] then '5256565618' # 0154
          when [true,  'show',    :bottom] then '6733298817' # 0155
          when [true,  'waiting', :top]    then USER_WAITING_RESP # 0197

          when [false, 'show',    :slit]   then GUEST_OTHERS_RESP # 0149 in search histories
          when [false, 'waiting', :slit]   then GUEST_OTHERS_RESP # 0149 in search histories
          when [true,  'show',    :slit]   then USER_OTHERS_RESP # 0199 in search histories
          when [true,  'waiting', :slit]   then USER_OTHERS_RESP # 0199 in search histories

          when [false, 'close_friends', :top]    then GUEST_CLOSE_FRIENDS_TOP_RESP # 0106 for backward compatibility
          when [false, 'close_friends', :slit]   then GUEST_CLOSE_FRIENDS_SLIT_RESP # 0107 for backward compatibility
          when [false, 'close_friends', :bottom] then GUEST_CLOSE_FRIENDS_BOTTOM_RESP # 0108 for backward compatibility
          when [true,  'close_friends', :top]    then USER_CLOSE_FRIENDS_TOP_RESP # 0156 for backward compatibility
          when [true,  'close_friends', :slit]   then USER_CLOSE_FRIENDS_SLIT_RESP # 0157 for backward compatibility
          when [true,  'close_friends', :bottom] then USER_CLOSE_FRIENDS_BOTTOM_RESP # 0158 for backward compatibility
          else nil
        end
      elsif %w(close_friends unfriends).include?(controller_name)
        case [user_signed_in?, controller_name, vertical_position]
          when [false, 'close_friends', :top]    then GUEST_CLOSE_FRIENDS_TOP_RESP # 0106
          when [false, 'close_friends', :slit]   then GUEST_CLOSE_FRIENDS_SLIT_RESP # 0107
          when [false, 'close_friends', :bottom] then GUEST_CLOSE_FRIENDS_BOTTOM_RESP # 0108
          when [false, 'unfriends',     :top]    then GUEST_REMOVED_TOP_RESP # 0109
          when [false, 'unfriends',     :slit]   then GUEST_REMOVED_SLIT_RESP # 0110
          when [false, 'unfriends',     :bottom] then GUEST_REMOVED_BOTTOM_RESP # 0111

          when [true,  'close_friends', :top]    then USER_CLOSE_FRIENDS_TOP_RESP # 0156
          when [true,  'close_friends', :slit]   then USER_CLOSE_FRIENDS_SLIT_RESP # 0157
          when [true,  'close_friends', :bottom] then USER_CLOSE_FRIENDS_BOTTOM_RESP # 0158
          when [true,  'unfriends',     :top]    then USER_REMOVED_TOP_RESP # 0159
          when [true,  'unfriends',     :slit]   then USER_REMOVED_SLIT_RESP # 0160
          when [true,  'unfriends',     :bottom] then USER_REMOVED_BOTTOM_RESP # 0161
          else nil
        end
      end

    if slot
      slot
    else
      case user_signed_in?
        when false then GUEST_OTHERS_RESP # 0149
        when true  then USER_OTHERS_RESP # 0199
      end
    end
  end

  def right_ad_slot_RESPonsive
    case user_signed_in?
      when false then '4977364015' # 0148
      when true  then '6454097215' # 0198
    end
  end

  def async_adsense_wrapper_id
    "async-adsense-#{SecureRandom.urlsafe_base64(10)}"
  end
end
