class Kaomoji
  HAPPY = [
      "✧*｡٩(ˊᗜˋ*)و✧*｡",
      "(*´ヮ`*)",
      ".:*･ﾟ(*´-`)ﾟ･*:.",
      ":゜☆ヽ(*’∀’*)/☆゜:。",
      "(n'∀')ηﾟ*｡:*!",
  ]

  SAFE_HAPPY = [
      "(๑•̀ㅂ•́)و✧",
      "٩(๑❛ᴗ❛๑)۶",
  ]

  UNHAPPY = [
      ":;(∩´﹏`∩);:",
  ]

  SHIROME = [
      "(ㆆ_ㆆ)"
  ]

  def self.happy
    SAFE_HAPPY.sample
  end

  def self.unhappy
    UNHAPPY.sample
  end

  def self.shirome
    SHIROME.sample
  end
end
