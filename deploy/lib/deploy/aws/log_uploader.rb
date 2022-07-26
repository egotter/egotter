class LogUploader
  REGION = 'ap-northeast-1'

  def initialize(name)
    @name = name
  end

  def upload(file)
    bucket = 'egotter-server-log'
    key = "#{@name}/#{File.basename(file)}"
    system("ssh #{@name} aws s3api put-object --bucket #{bucket} --key #{key} --body #{file}")
  rescue => e
    logger.warn "upload_log: #{e.inspect}"
  end

  def logger
    Logger.new(STDOUT)
  end
end
