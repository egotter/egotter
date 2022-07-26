class LogUploader
  REGION = 'ap-northeast-1'
  BUCKET = 'egotter-server-log'

  def initialize(name)
    @name = name
    @files = []
  end

  def with_ssh
    @ssh = true
    self
  end

  def add(file)
    @files << file
    self
  end

  def upload
    @files.each do |file|
      key = "#{@name}/#{File.basename(file)}"
      cmd = "aws s3api put-object --bucket #{BUCKET} --key #{key} --body #{file}"
      cmd = "ssh #{@name} #{cmd}" if @ssh
      result = `#{cmd}`
      result = JSON.parse(result) rescue result
      logger.info "File uploaded: file=#{file} result=#{result}"
    rescue => e
      logger.warn "Uploading failed: #{e.inspect} file=#{file}"
    end
  end

  def logger
    Logger.new(STDOUT)
  end
end
