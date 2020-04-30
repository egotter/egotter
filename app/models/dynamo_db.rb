# -*- SkipSchemaAnnotations
require 'base64'
require 'zlib'
require 'fileutils'

module DynamoDB
  REGION = 'ap-northeast-1'
  TABLE_NAME = "egotter.#{Rails.env}.twitter_users"
  TABLE_TTL = 1.day

  module_function

  def enabled?
    ENV['DISABLE_DYNAMO_DB_TWITTER_USER'] != '1'
  end

  def cache_alive?(time)
    Time.zone.now - time < TABLE_TTL
  end
end
