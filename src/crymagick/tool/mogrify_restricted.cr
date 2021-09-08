require "./mogrify"

class CryMagick::Tool
  class MogrifyRestricted < Mogrify
    def format(*args)
      raise ArgumentError.new("you must call #format on a CryMagick::Image directly")
    end
  end
end
