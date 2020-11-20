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

  def cdn_url
    image.attached? ? "https://#{ENV['OG_IMAGE_ASSET_HOST']}/#{image.blob.key}" : nil
  end

  def update_acl(value = 'public-read')
    config = YAML.load(ERB.new(Rails.root.join('config/storage.yml').read).result)['amazon']
    client = Aws::S3::Client.new(region: config['region'], retry_limit: 4, http_open_timeout: 3, http_read_timeout: 3)
    client.put_object_acl(acl: value, bucket: config['bucket'], key: image.blob.key)
  end

  def update_acl_async
    UpdateCloseFriendsOgImageAclWorker.perform_async(id)
  end

  class Generator

    OG_IMAGE_IMAGEMAGICK = ENV['OG_IMAGE_IMAGEMAGICK']
    OG_IMAGE_OUTLINE = Rails.root.join('app/views/og_images/egotter_og_outline_840x450.png')
    OG_IMAGE_HEART = Rails.root.join('app/views/og_images/heart_300x350.svg.erb').read
    OG_IMAGE_RECT = Rails.root.join('app/views/pink_48x48.gif')
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
        self.class.generate_image(text, heart, @outfile)

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
      path = ImagesLoader.dir_path(@twitter_user.uid)
      MX_RMFILE.synchronize do
        FileUtils.rm_rf(path) if File.exist?(path)
      end

      MX_RMFILE.synchronize do
        File.delete(@outfile) if @outfile && File.exist?(@outfile)
      end
    end

    private

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
        image_files = ApplicationRecord.benchmark("Benchmark CloseFriendsOgImage::Generator uid=#{uid}") { images_loader.load }

        hash = hash.map do |key, value|
          if key.match?(/^image_url/)
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

      MX_CONVERT = Mutex.new

      def generate_image(text, heart, outfile)
        MX_CONVERT.synchronize do
          system(%Q(#{OG_IMAGE_IMAGEMAGICK} #{OG_IMAGE_OUTLINE} -font "#{OG_IMAGE_FONT}" -fill black -pointsize 24 -interline-spacing 20 -annotate +50+120 "#{text}" #{outfile}))
          Tempfile.open(['heart', '.svg']) do |f|
            f.write heart
            system(%Q(#{OG_IMAGE_IMAGEMAGICK} #{outfile} #{f.path} -gravity center -geometry +200+0 -composite #{outfile}))
          end
        end
      end
    end
  end

  class ImagesLoader
    def initialize(uid, urls)
      @uid = uid
      @urls = urls
      @queue = Queue.new
      @concurrency = 10
    end

    MX_MKDIR = Mutex.new

    class << self
      def dir_path(uid)
        path = Rails.root.join("public/og_image/profile_images_#{uid}")
        MX_MKDIR.synchronize do
          Dir.mkdir(path) unless File.exist?(path)
        end
        path
      end
    end

    def load
      Parallel.each(@urls, in_threads: @concurrency) do |url|
        basename = File.basename(url)
        filename = "#{self.class.dir_path(@uid)}/profile_image_#{@uid}_#{basename}"
        unless File.exist?(filename)
          image = ApplicationRecord.benchmark("Benchmark CloseFriendsOgImage::ImagesLoader uid=#{@uid} url=#{url}") { open(url) }
          File.open(filename, 'wb') do |f|
            f.write(image)
          end
        end
        @queue << [url, filename]
      rescue => e
        Rails.logger.debug { "#{self.class}##{__method__}: open url failed url=#{url} exception=#{e.inspect}" }
        @queue << [url, nil]
      end

      @queue.size.times.map { @queue.pop }.to_h
    end

    def open(url, retries: 3)
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
        raise RetryExhausted.new("#{e.inspect}")
      end
    end

    class RetryExhausted < StandardError; end
  end
end
