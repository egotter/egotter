# TODO Remove later
module WorkerErrorHandler
  def handle_worker_error(ex, **props)
    Airbag.exception ex, {method: __method__}.merge(props)
  end
end
