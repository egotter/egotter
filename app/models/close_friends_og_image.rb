# == Schema Information
#
# Table name: close_friends_og_images
#
#  id         :bigint(8)        not null, primary key
#  uid        :bigint(8)        not null
#  properties :json
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_close_friends_og_images_on_uid  (uid) UNIQUE
#
require 'yaml'
require 'tempfile'

class CloseFriendsOgImage < ApplicationRecord
  has_one_attached :image

  validates :uid, presence: true, uniqueness: true

  def fresh?
    updated_at && updated_at > 12.hours.ago
  end

  def s3_url
    image.attached? ? "s3://#{storage_config['bucket']}/#{image.blob.key}" : nil
  end

  def cdn_url
    image.attached? ? "https://#{ENV['OG_IMAGE_ASSET_HOST']}/#{image.blob.key}" : nil
  end

  def lambda_url
    image.attached? ? "https://#{ENV['OG_IMAGE_LAMBDA_HOST']}?uid=#{uid}" : nil
  end

  def update_acl(value = 'public-read')
    client = Aws::S3::Client.new(region: storage_config['region'], retry_limit: 4, http_open_timeout: 3, http_read_timeout: 3)
    client.put_object_acl(acl: value, bucket: storage_config['bucket'], key: image.blob.key)
  end

  def storage_config
    @storage_config ||= YAML.load(ERB.new(Rails.root.join('config/storage.yml').read).result)['amazon']
  end

  def update_acl_async
    UpdateCloseFriendsOgImageAclWorker.perform_async(id)
  end

  class << self
    def lambda_url(uid)
      "https://#{ENV['OG_IMAGE_LAMBDA_HOST']}?uid=#{uid}"
    end
  end

  class Generator

    OG_IMAGE_IMAGEMAGICK_BIN = ENV['OG_IMAGE_IMAGEMAGICK']
    OG_IMAGE_OUTLINE = Rails.root.join('app/views/og_images/egotter_og_outline_840x450.png')
    OG_IMAGE_HEART = Rails.root.join('app/views/og_images/heart_300x350.svg.erb').read
    OG_IMAGE_RECT = Rails.root.join('app/views/og_images/pink_48x48.gif')
    OG_IMAGE_FONT = Rails.root.join('app/views/og_images/azukiP.ttf')
    OG_IMAGE_TMP_DIR = Rails.root.join('public/og_image')

    def initialize(twitter_user)
      @twitter_user = twitter_user
    end

    def generate(friends)
      @outfile = self.class.outfile_path(@twitter_user.uid)
      text = I18n.t('og_image_text.close_friends', user: @twitter_user.screen_name, friend1: friends[0][:screen_name], friend2: friends[1][:screen_name], friend3: friends[2][:screen_name])
      heart = self.class.generate_heart_image(@twitter_user.uid, friends)

      begin
        benchmark("Write text uid=#{@twitter_user.uid}") do
          write_text_to_image(text, @outfile)
        end
        benchmark("Composite images uid=#{@twitter_user.uid}") do
          composite_images(heart, @outfile)
        end

        image = CloseFriendsOgImage.find_or_initialize_by(uid: @twitter_user.uid)
        image.image.purge if image.image.attached?
        image.image.attach(io: File.open(@outfile), filename: File.basename(@outfile))
        image.assign_attributes(properties: {twitter_user_id: @twitter_user.id})
        image.save!
        image.update_acl_async
      ensure
        cleanup
      end
    end

    require 'fileutils'

    MX_RMFILE = Mutex.new

    def cleanup
      ImagesLoader.cleanup(@twitter_user.uid)

      MX_RMFILE.synchronize do
        File.delete(@outfile) if @outfile && File.exist?(@outfile)
      end
    end

    private

    def write_text_to_image(text, outfile)
      if File.exists?(OG_IMAGE_IMAGEMAGICK_BIN)
        system(%Q(env OMP_NUM_THREADS=1 MAGICK_THREAD_LIMIT=1 #{OG_IMAGE_IMAGEMAGICK_BIN} #{OG_IMAGE_OUTLINE} -font "#{OG_IMAGE_FONT}" -fill black -pointsize 24 -interline-spacing 20 -annotate +50+120 "#{text}" #{outfile}))
      else
        raise "#{OG_IMAGE_IMAGEMAGICK_BIN} is not found"
      end
    end

    def composite_images(heart, outfile)
      if File.exists?(OG_IMAGE_IMAGEMAGICK_BIN)
        Tempfile.open(['heart', '.svg']) do |f|
          f.write heart
          system(%Q(env OMP_NUM_THREADS=1 MAGICK_THREAD_LIMIT=1 #{OG_IMAGE_IMAGEMAGICK_BIN} #{outfile} #{f.path} -gravity center -geometry +200+0 -composite #{outfile}))
        end
      else
        raise "#{OG_IMAGE_IMAGEMAGICK_BIN} is not found"
      end
    end

    def benchmark(message, &block)
      self.class.benchmark(message, &block)
    end

    class << self

      MX_MKDIR = Mutex.new

      def outfile_path(uid)
        MX_MKDIR.synchronize do
          Dir.mkdir(OG_IMAGE_TMP_DIR) unless File.exist?(OG_IMAGE_TMP_DIR)
        end
        file = "close_friends_og_image.#{uid}.#{Date.today}.#{Process.pid}.#{Thread.current.object_id.to_s(36)}.png"
        Rails.root.join(OG_IMAGE_TMP_DIR, file)
      end

      def generate_heart_image(uid, users)
        hash = {}
        image_urls = []

        100.times do |i|
          user = users[i]

          if i < 3
            hash["screen_name_#{i}"] = user ? user[:screen_name] : ''
          end

          if user
            hash["image_url_#{i}"] = user[:profile_image_url_https]
            image_urls << user[:profile_image_url_https]
          else
            hash["image_url_#{i}"] = OG_IMAGE_RECT
          end
        end

        images_loader = ImagesLoader.new(uid, image_urls)
        image_files = benchmark("all images loaded uid=#{uid}") { images_loader.load }

        hash = hash.map do |key, value|
          if key.match?(/^image_url/) && value.to_s.match?(/^http/)
            url, file = image_files.find { |url, _| url == value }
            if url && file
              [key, file]
            else
              Rails.logger.debug { "#{self.class}##{__method__}: file not found url=#{value}" }
              [key, value]
            end
          else
            [key, value]
          end
        end.to_h

        ERB.new(OG_IMAGE_HEART).result_with_hash(hash)
      end

      def benchmark(message, &block)
        ApplicationRecord.benchmark("Benchmark #{self} #{message}", &block)
      end
    end
  end

  require 'parallel'

  class ImagesLoader
    def initialize(uid, urls)
      @uid = uid
      @urls = urls
      @concurrency = 10
    end

    def load
      # dir_path # Create a dir
      result = []

      @urls.each_slice(@concurrency) do |group|
        threads = group.map do |url|
          Thread.new(url) do |u|
            [u, url2base64(u)]
          rescue => e
            nil
          end
        end

        threads.each(&:join)
        result.concat(threads.map(&:value).compact)
      end

      result.to_h
    end

    class << self
      def default_rect_base64
        if instance_variable_defined?(:@default_rect_base64)
          @default_rect_base64
        else
          binary = File.binread(CloseFriendsOgImage::Generator::OG_IMAGE_RECT)
          @default_rect_base64 = "data:image/gif;base64,#{Base64.strict_encode(binary)}"
        end
      end

      def cleanup(uid)
        # path = new(uid, nil).send(:dir_path)
        # File.delete(*Dir.glob("#{path}/*"))
      end
    end

    private

    require 'base64'

    def url2base64(url)
      ext = extract_ext(url)
      if !ext || (binary = open_url(url)).empty?
        self.class.default_rect_base64
      else
        "data:image/#{ext};base64,#{Base64.strict_encode(binary)}"
      end
    end

    def extract_ext(url)
      ext = File.extname(url)
      case ext
      when 'png', 'gif'
        ext
      when 'jpeg', 'jpg'
        'jpeg'
      else
        nil
      end
    end

    def url2file(url)
      path = file_path(url)
      unless File.exist?(path)
        binary = open_url(url)
        binary = File.binread(CloseFriendsOgImage::Generator::OG_IMAGE_RECT) if binary.empty?
        File.binwrite(path, binary)
      end
      path
    end

    def file_path(url)
      "#{dir_path}/profile_image_#{@uid}_#{File.basename(url)}"
    end

    def dir_path
      path = Rails.root.join("public/og_image/profile_images_#{@uid}")
      Dir.mkdir(path) unless File.exist?(path)
      path
    end

    def open_url(url, retries: 3)
      uri = URI.parse(url)
      https = Net::HTTP.new(uri.host, uri.port)
      https.use_ssl = true
      https.open_timeout = 1
      https.read_timeout = 1
      req = Net::HTTP::Get.new(uri)
      https.start { https.request(req) }.body
    rescue Net::OpenTimeout => e
      if (retries -= 1) >= 0
        sleep(rand(2) + 1)
        retry
      else
        Airbag.info "#{self.class}##{__method__}: #{e.inspect} url=#{url}"
        ''
      end
    rescue => e
      Airbag.info "#{self.class}##{__method__}: #{e.inspect} url=#{url}"
      ''
    end

    def benchmark(message, &block)
      ApplicationRecord.benchmark("Benchmark #{self.class} #{message}", &block)
    end
  end
end
