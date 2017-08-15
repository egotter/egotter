class Nikaidate::Opinion < ActiveRecord::Base

  with_options(dependent: :destroy, validate: false, autosave: false) do |obj|
    obj.belongs_to :party, primary_key: :uid, foreign_key: :uid
    obj.has_many :citations, primary_key: :status_id, foreign_key: :status_id
    obj.has_many :posts, through: :citations
  end

  validates :status_id, uniqueness: true

  def initialize(attrs)
    if attrs.has_key?(:status)
      status = attrs[:status]
      super(status2hash(status))
    else
      super
    end
  end

  def tweet_id
    status_id
  end

  def tweeted_at
    attrs_hash[:created_at]
  end

  def user
    party
  end

  def attrs_hash
    @attrs_hash ||= Hashie::Mash.new(JSON.load(attrs_json))
  end

  delegate :text, to: :attrs_hash

  private

  def status2hash(status)
    s = Hashie::Mash.new(status.to_hash)
    {uid: s.user.id, status_id: s.id, attrs_json: s.slice(*::Status::STATUS_SAVE_KEYS).to_json}
  end
end
