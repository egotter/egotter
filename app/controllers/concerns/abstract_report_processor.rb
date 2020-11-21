module AbstractReportProcessor
  include ReportStatusValidator

  def initialize(uid, text)
    @uid = uid
    @text = text
  end

  def message_length
    15
  end

  def stop_requested?
    @text.length <= message_length && @text.match?(stop_regexp)
  end

  def restart_requested?
    @text.length <= message_length && @text.match?(restart_regexp)
  end

  def continue_requested?
    @text.length <= message_length && @text.match?(continue_regexp)
  end

  def received?
    @text.length <= message_length && @text.match?(received_regexp)
  end

  def send_requested?
    @text.length <= message_length && @text.match?(send_regexp)
  end

  def stop_report
    raise NotImplementedError
  end

  def restart_report
    raise NotImplementedError
  end

  def continue_report
    raise NotImplementedError
  end

  def send_report
    raise NotImplementedError
  end
end
