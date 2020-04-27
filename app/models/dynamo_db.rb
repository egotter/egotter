# -*- SkipSchemaAnnotations
require 'base64'
require 'zlib'
require 'fileutils'

module DynamoDB
  REGION = 'ap-northeast-1'
  TABLE_NAME = "egotter.#{Rails.env}.twitter_users"
end
