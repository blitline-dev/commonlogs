module CommonLog
  class Config

    @dest_folder = nil

    def self.destination_folder
      return @dest_folder if @dest_folder

      @dest_folder = ENV['COMMON_LOG_FOLDER'] || "/var/log/commonlogs".freeze
      # Legacy options
      @dest_folder = "/var/log/commonlog".freeze unless File.directory?(@dest_folder)

      return @dest_folder
    end
  end
end
