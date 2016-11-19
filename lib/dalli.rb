module CommonLogs
  class Dalli
    def initialize
      begin
        @memcached = Dalli::Client.new('localhost:11211', compress: false, expires_in: 86_400)
      rescue => ex
        puts "Failed to initialize Dalli #{ex.message}"
        @memcached = nil
      end
    end

    def set(key, data)
      return nil unless @memcached
      @memcached.set(key, data)
    end

    def get(key)
      return nil unless @memcached
      @memcached.get(key)
    end
  end
end