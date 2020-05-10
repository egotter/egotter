module ModalHelper
  def modal_trigger(target:, &block)
    content_tag 'span', style: 'cursor : pointer;', data: {target: "##{target}", toggle: 'modal'}, &block
  end

  def modal_dialog(id:, title:, body: nil, button: nil, data: nil, size: nil, &block)
    button = {positive: 'OK', category: 'primary'} unless button
    button[:category] = 'primary' unless button[:category]
    data = {} unless data
    data_attrs = data.map { |k, v| %Q(data-#{k.to_s.gsub(/_/, '-')}="#{v}") }.join(' ')

    <<~HTML.html_safe
      <div class="modal fade" id="#{id}" tabindex="-1" role="dialog" aria-labelledby="exampleModalLabel" aria-hidden="true" #{data_attrs}>
        <div class="modal-dialog #{size}" role="document">
          <div class="modal-content">
            <div class="modal-header">
              <h5 class="modal-title">#{title}</h5>
              <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                <span aria-hidden="true">&times;</span>
              </button>
            </div>
            <div class="modal-body">
              #{block_given? ? capture(&block) : body}
            </div>
            <div class="modal-footer">
              #{modal_negative_button(button[:negative]) if button[:negative]}
              <button type="button" class="btn btn-#{button[:category]} positive" data-dismiss="modal">#{button[:positive]}</button>
            </div>
          </div>
        </div>
      </div>
    HTML
  end

  def modal_negative_button(label)
    <<~HTML.html_safe
      <button type="button" class="btn btn-outline-secondary negative" data-dismiss="modal">#{label}</button>
    HTML
  end
end
