module AdsenseHelper
  def left_ad_slot(signed_in, action, vertical)
    slot =
      case [signed_in, action, vertical]
        when [true,  'new',                    :top]    then '1499207213'
        when [true,  'show',                   :top]    then '2975940411'
        when [true,  'show',                   :bottom] then '4452673613'
        when [true,  'show',                   :slit]   then '9958552019'
        when [true,  'search_histories/index', :slit]   then '5378418414'
        when [false, 'new',                    :top]    then '4742208415'
        when [false, 'show',                   :top]    then '6218941612'
        when [false, 'show',                   :bottom] then '7695674812'
        when [false, 'show',                   :slit]   then '5528352415'
        when [false, 'search_histories/index', :slit]   then '3901685219'
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
end
