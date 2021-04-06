require 'rails_helper'

RSpec.describe Logging do
  controller ApplicationController do
    include Logging
  end

  describe '#track_event' do
    subject { controller.track_event('name', 'properties') }
    it do
      expect(controller).to receive_message_chain(:ahoy, :track).with('name', 'properties')
      subject
    end
  end

  describe '#track_sign_in_event' do
    subject { controller.track_sign_in_event(context: 'c', via: 'v') }
    it do
      expect(controller).to receive_message_chain(:ahoy, :track).with('Sign in', via: 'v')
      subject
    end
  end
end
