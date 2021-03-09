module FaqHelper
  def faq_id(value)
    (@faq_ids ||= []) << (value == :auto ? "faq-id-#{@faq_ids.size}" : value)
  end

  def faq_question(value)
    (@faq_questions ||= []) << value
  end

  def faq_answer(&block)
    (@faq_answers ||= []) << capture(&block)
  end

  def faq_ids
    @faq_ids
  end

  def faq_questions
    @faq_questions
  end

  def faq_answers
    @faq_answers
  end

  def flush_faq
    @faq_ids = nil
    @faq_questions = nil
    @faq_answers = nil
  end
end
