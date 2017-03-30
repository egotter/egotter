module AdsenseHelper
  NG_UIDS = [740700661939994624]

  def ad_ng_twitter_user?(twitter_user)
    NG_UIDS.include? twitter_user&.uid&.to_i
  end

  def left_ad_slot(signed_in, action, vertical)
    slot =
      case [signed_in, action, vertical]
        when [true,  'new',                    :top]    then '1499207213'
        when [true,  'show',                   :top]    then '2975940411'
        when [true,  'show',                   :bottom] then '4452673613'
        when [true,  'show',                   :slit]   then '9958552019'
        when [true,  'search_histories/index', :slit]   then '5378418414'
        when [true,  'waiting',                 :top]   then '2340125210'
        when [false, 'new',                    :top]    then '4742208415'
        when [false, 'show',                   :top]    then '6218941612'
        when [false, 'show',                   :bottom] then '7695674812'
        when [false, 'show',                   :slit]   then '5528352415'
        when [false, 'search_histories/index', :slit]   then '3901685219'
        when [false, 'waiting',                :top]    then '9863392014'
        else nil
      end

    if slot
      slot
    else
      signed_in ? '8405195212' : '6928462015'
    end
  end

  def right_ad_slot(signed_in)
    signed_in ? '8092612016' : '8511414414'
  end

  def left_ad_slot_responsive(vertical_position)
    slot =
      if %w(searches search_results).include?(controller_name)
        case [user_signed_in?, action_name, vertical_position]
          when [false, 'new',     :top]    then '1384769219' # 0101
          when [false, 'new',     :bottom] then '2861502412' # 0102
          when [false, 'show',    :top]    then '4338235610' # 0103
          when [false, 'show',    :middle] then '2442700011' # 0104
          when [false, 'show',    :bottom] then '5814968816' # 0105
          when [false, 'waiting', :top]    then '9407563612' # 0147

          when [true,  'new',     :top]    then '6872899613' # 0151
          when [true,  'new',     :bottom] then '2303099214' # 0152
          when [true,  'show',    :top]    then '3779832415' # 0153
          when [true,  'show',    :middle] then '5256565618' # 0154
          when [true,  'show',    :bottom] then '6733298817' # 0155
          when [true,  'waiting', :top]    then '7930830419' # 0197

          when [false, 'show',    :slit]   then '8070431219' # 0149 in search histories
          when [false, 'waiting', :slit]   then '8070431219' # 0149 in search histories
          when [true,  'show',    :slit]   then '3500630816' # 0199 in search histories
          when [true,  'waiting', :slit]   then '3500630816' # 0199 in search histories

          when [false, 'close_friends', :top]    then '1105567611' # 0106 for backward compatibility
          when [false, 'close_friends', :slit]   then '3919433211' # 0107 for backward compatibility
          when [false, 'close_friends', :bottom] then '2582300812' # 0108 for backward compatibility
          when [true,  'close_friends', :top]    then '8210032018' # 0156 for backward compatibility
          when [true,  'close_friends', :slit]   then '9686765218' # 0157 for backward compatibility
          when [true,  'close_friends', :bottom] then '2163498414' # 0158 for backward compatibility
          else nil
        end
      elsif %w(close_friends unfriends).include?(controller_name)
        case [user_signed_in?, controller_name, vertical_position]
          when [false, 'close_friends', :top]    then '1105567611' # 0106
          when [false, 'close_friends', :slit]   then '3919433211' # 0107
          when [false, 'close_friends', :bottom] then '2582300812' # 0108
          when [false, 'unfriends',     :top]    then '4059034018' # 0109
          when [false, 'unfriends',     :slit]   then '5396166411' # 0110
          when [false, 'unfriends',     :bottom] then '7012500419' # 0111

          when [true,  'close_friends', :top]    then '8210032018' # 0156
          when [true,  'close_friends', :slit]   then '9686765218' # 0157
          when [true,  'close_friends', :bottom] then '2163498414' # 0158
          when [true,  'unfriends',     :top]    then '3640231616' # 0159
          when [true,  'unfriends',     :slit]   then '5116964815' # 0160
          when [true,  'unfriends',     :bottom] then '6593698015' # 0161
          else nil
        end
      end

    if slot
      slot
    else
      case user_signed_in?
        when false then '8070431219' # 0149
        when true  then '3500630816' # 0199
      end
    end
  end

  def right_ad_slot_responsive
    case user_signed_in?
      when false then '4977364015' # 0148
      when true  then '6454097215' # 0198
    end
  end
end
