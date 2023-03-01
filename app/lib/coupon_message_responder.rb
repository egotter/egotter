class CouponMessageResponder < AbstractMessageResponder

  def processor_class
    Processor
  end

  class Processor
    include AbstractReportProcessor

    def message_length
      100
    end

    def received?
      return false if @text.length > message_length

      if @text.match?(coupon_regexp)
        @coupon = true
      end
    end

    def coupon_regexp
      /クーポン|割引|半額/
    end

    def send_message
      if @coupon
        CreateCouponMessageWorker.perform_async(@uid)
      end
    end
  end
end
