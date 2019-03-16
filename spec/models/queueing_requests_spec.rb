require 'rails_helper'

RSpec.describe QueueingRequests do
  it_should_behave_like 'Time limited queue'
end
