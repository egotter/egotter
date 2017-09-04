require 'stripe'

module StripeDB
  def self.table_name_prefix
    'stripe_'
  end
end

if File.basename($0) == 'annotate' && Rails.env.development?
  StripeDb = StripeDB
end