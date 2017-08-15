require 'open-uri'

namespace :nikaidate do
  namespace :posts do
    desc 'create'
    task create: :environment do
      sigint = false
      Signal.trap 'INT' do
        puts 'intercept INT and stop ..'
        sigint = true
      end

      archive_ids =
        if ENV['ARCHIVE_IDS']
          ENV['ARCHIVE_IDS'].remove(' ').split(',')
        else
          urls = Nokogiri::HTML(open('http://kabumatome.doorblog.jp/').read).xpath("//div[@class='sidebody']/a/@href").map { |tag| tag.text }
          urls.map { |url| url.match(%r[http://kabumatome.doorblog.jp/archives/(\d+).html])[1] }
        end

      archive_ids.each do |archive_id|
        url = "http://kabumatome.doorblog.jp/archives/#{archive_id}.html"
        html = open(url).read
        doc = Nokogiri::HTML(html)

        post = Nikaidate::Post.find_or_initialize_by(archive_id: archive_id)
        post.update!(
          url: url,
          title: doc.xpath('//title').map(&:text).first.remove(/ : 市況かぶ全力２階建$/),
          description: doc.xpath("//meta[@name='description']/@content").map(&:text).first,
          tags_json: doc.xpath("//dd[@class='article-category1']/a").map(&:text).first.split('・').to_json,
          status_urls_json: doc.xpath("//blockquote[@class='twitter-tweet']/a/@href").map(&:text).uniq.to_json,
          published_at: Time.zone.now
        )

        puts "#{post.archive_id} #{post.title}"

        break if sigint
      end
    end

    desc 'update_opinions'
    task update_opinions: :environment do
      archive_ids =
        if ENV['ARCHIVE_IDS']
          ENV['ARCHIVE_IDS'].remove(' ').split(',')
        else
          Nikaidate::Post.pluck(:archive_id)
        end

      Nikaidate::Post.where(archive_id: archive_ids).find_each do |post|
        status_ids = post.status_urls.map { |url| url.match(%r[https://twitter.com/\w+/status/(\d+)])[1] }.map(&:to_i)
        if status_ids.size > 100
          raise "Too many statuses #{status_ids.size}"
        end

        begin
          tries ||= 3
          statuses = Bot.api_client.statuses(status_ids).index_by(&:id)
        rescue Twitter::Error => e
          if e.message == 'execution expired'
            retry unless (tries -= 1).zero?
          else
            raise
          end
        end

        statuses = status_ids.map { |id| statuses[id] }.compact

        opinions =
          statuses.map do |status|
            if Nikaidate::Opinion.exists?(status_id: status.id)
              Nikaidate::Opinion.find_by(status_id: status.id)
            else
              ActiveRecord::Base.transaction do
                Nikaidate::Party.create!(user: status.user) unless Nikaidate::Party.exists?(uid: status.user.id)
                Nikaidate::Opinion.create!(status: status)
              end
            end
          end

        post.opinion_ids = opinions.map(&:status_id)
        post.reload

        puts "#{post.archive_id} status_ids: #{status_ids.size} statuses: #{statuses.size} opinions #{post.opinions.size} parties #{post.parties.size}"
      end
    end
  end
end
