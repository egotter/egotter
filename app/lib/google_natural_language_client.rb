require 'google/cloud/language'

class GoogleNaturalLanguageClient

  def initialize
    @client = service_account_authorization
  end

  def analyze(text, type: 'PLAIN_TEXT', language: 'ja')
    response = @client.analyze_sentiment(document: {content: text, type: type, language: language})
    response.document_sentiment
  end

  def service_account_authorization
    Google::Cloud::Language.language_service do |config|
      config.credentials = ".google/service_account_natural_language.json"
    end
  end
end
