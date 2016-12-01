# `module Twitter` is reserved for `Twitter gem`
module TwitterDB
  class Base < ActiveRecord::Base
    establish_connection :twitter
    self.abstract_class = true
  end
end
