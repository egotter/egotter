module ClickIdsHelper
  def fuzzy_invitation_count(value)
    if value >= 100
      '100+'
    elsif value >= 1
      v = ((value / 10.0).floor * 10).to_i
      "#{v}-#{v + 10}"
    else
      '0'
    end
  end
end
