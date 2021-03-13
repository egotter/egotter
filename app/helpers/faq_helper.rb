module FaqHelper
  def faq_section(value, &block)
    @faq_section = value
    @faq_questions = []

    yield

    @faq_sections ||= {}
    @faq_sections[value] = @faq_questions
  end

  def faq_contents(id, value)
    @faq_contents ||= Hash.new { |h, k| h[k] = [] }
    @faq_contents[@faq_section] << {id: id, text: value}
  end

  def faq_generate_id(value)
    value == :auto ? "faq-id-#{@faq_questions.size}" : value
  end

  def faq_question(value, id: :auto, &block)
    @faq_questions << {id: faq_generate_id(id), text: value, answer: capture(&block)}
    faq_contents(id, value)
  end
end
