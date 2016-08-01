class InformationController < ApplicationController
  layout false

  def index
    @lists = [
      %w(2016/07/31 通知ページを作成しました),
      %w(2016/07/28 検索を高速化しました),
      %w(2016/07/27 トップページのレイアウトを<br>修正しました),
      %w(2016/07/26 トップページのレイアウトを<br>修正しました),
      %w(2016/07/25 ページの読み込みを<br>高速化しました),
      %w(2016/07/24 スマートフォン向けのアイコンを<br>設置しました),
    ].freeze
    render json: {status: 200, html: render_to_string}, status: 200
  end
end
