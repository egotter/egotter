module ReportStatusValidator
  def validate_report_status(uid)
    unless (user = User.find_by(uid: uid))
      CreatePeriodicReportUnregisteredMessageWorker.perform_async(uid)
      return
    end

    unless user.authorized?
      CreatePeriodicReportUnauthorizedMessageWorker.perform_async(user.id)
      return
    end

    unless user.enough_permission_level?
      CreatePeriodicReportPermissionLevelNotEnoughMessageWorker.perform_async(user.id)
      return
    end

    if user.banned?
      CreatePeriodicReportBlockerNotPermittedMessageWorker.perform_async(user.id)
      return
    end

    user
  end
end
