# -*- SkipSchemaAnnotations
require 'zlib'
require 'fileutils'

module Efs
  module_function

  def enabled?
    ENV['DISABLE_EFS_TWITTER_USER'] != '1'
  end
end
