require 'active_support/concern'

module Concerns::Report::HasToken
  extend ActiveSupport::Concern

  class_methods do
    def generate_token
      begin
        t = ReadConfirmationToken.generate
      end while exists?(token: t)
      t
    end
  end

  included do
    validates :token, presence: true, uniqueness: true
  end
end