module CommonLog
  class Context

    attr_reader :path_token
    def initialize(path_token)
      @path_token = path_token
    end

  end
end