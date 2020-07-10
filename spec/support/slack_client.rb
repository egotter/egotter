module SendNothing
  def send_message(*args)
    'ok (send nothing in test environment)'
  end
end

SlackClient.prepend SendNothing
