class Nikaidate::Post < ActiveRecord::Base

  with_options(dependent: :destroy, validate: false, autosave: false) do |obj|
    obj.has_many :citations, primary_key: :archive_id, foreign_key: :archive_id
    obj.has_many :opinions, through: :citations
    obj.has_many :parties, through: :opinions
  end

  def to_param
    archive_id
  end

  def status_urls
    @status_urls ||= JSON.parse(status_urls_json)
  end

  def tags
    @tags ||= JSON.parse(tags_json)
  end
end
