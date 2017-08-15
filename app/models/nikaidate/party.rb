class Nikaidate::Party < ActiveRecord::Base

  with_options(dependent: :destroy, validate: false, autosave: false) do |obj|
    obj.has_many :opinions, primary_key: :uid, foreign_key: :uid
  end

  validates :uid, uniqueness: true

  def initialize(attrs)
    if attrs.has_key?(:user)
      super(user2hash(attrs[:user]))
    else
      super
    end
  end

  def to_param
    uid
  end

  def mention_name
    "@#{screen_name}"
  end

  def attrs_hash
    @attrs_hash ||= Hashie::Mash.new(JSON.load(attrs_json))
  end

  delegate :name, :friends_count, :followers_count, :profile_image_url_https, :protected, :verified, :suspended, :description, to: :attrs_hash

  private

  def user2hash(user)
    u = Hashie::Mash.new(user.to_hash)
    {uid: user.id, screen_name: user.screen_name, attrs_json: TwitterUser.collect_user_info(u)}
  end
end
