require_relative '../logger'

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

  def add_all
    add('log/production.log').
        add('log/puma.log').
        add('log/sidekiq.log').
        add('log/sidekiq_misc.log').
        add('log/airbag.log').
        add('log/cron.log').
        add('/var/log/nginx/access.log').
        add('/var/log/nginx/error.log')
  end

  def upload
    @files.each do |file|
      unless File.exist?(file)
        logger.info "#{file} not found"
        next
      end

      key = "#{@name}/#{File.basename(file)}"
      cmd = "aws s3 cp #{file} s3://#{BUCKET}/#{key}"
      cmd = "ssh #{@name} #{cmd}" if @ssh
      `#{cmd}`
      logger.info "File uploaded: file=#{file}"
    rescue => e
      logger.warn "Uploading failed: #{e.inspect} file=#{file}"
    end
  end

  def logger
    Deploy::Logger.instance
  end
end
