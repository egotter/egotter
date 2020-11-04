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
      @outfile = self.class.outfile_path(twitter_user.uid)
      text = I18n.t('og_image_text.close_friends', user: @twitter_user.screen_name, friend1: friends[0][:screen_name], friend2: friends[1][:screen_name], friend3: friends[2][:screen_name])
      heart = self.class.generate_heart_image(friends)

      begin
        self.class.generate_image(text, heart, @outfile)

        image = CloseFriendsOgImage.find_or_initialize_by(uid: @twitter_user.uid)
        image.image.purge if image.image.attached?
        image.image.attach(io: File.open(@outfile), filename: File.basename(@outfile))
        image.assign_attributes(properties: {twitter_user_id: @twitter_user.id})
        image.save!
        image.update_acl_async
      ensure
        delete_outfile
      end
    end

    MX_RMFILE = Mutex.new

    def delete_outfile
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

      def generate_heart_image(users)
        hash = {}

        100.times do |i|
          user = users[i]

          if i < 3
            hash["screen_name_#{i}"] = user ? user[:screen_name] : ''
          end

          hash["image_url_#{i}"] = user ? user[:profile_image_url_https] : OG_IMAGE_RECT
        end

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
end
