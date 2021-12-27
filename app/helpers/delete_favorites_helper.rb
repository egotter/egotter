module DeleteFavoritesHelper
  def delete_favorites_free_tab?
    delete_favorites_mypage_path.remove(/\?.+/) == request.path
  end

  def delete_favorites_premium_tab?
    delete_favorites_mypage_premium_path.remove(/\?.+/) == request.path
  end

  def delete_favorites_history_tab?
    delete_favorites_mypage_history_path.remove(/\?.+/) == request.path
  end
end
