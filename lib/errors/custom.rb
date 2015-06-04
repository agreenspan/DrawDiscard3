module Errors

  class CustomException < StandardError
    def initialize(data)
      @data = data
    end
  end

end
