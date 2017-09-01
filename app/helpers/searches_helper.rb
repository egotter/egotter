module SearchesHelper
  def search_form_id
    "search-form-#{SecureRandom.urlsafe_base64(10)}"
  end

  def search_input_id
    "search-input-#{SecureRandom.urlsafe_base64(10)}"
  end
end
