module CommonLog
  class Config

    @dest_folder = nil

    def self.destination_folder
      return @dest_folder if @dest_folder

      @dest_folder = ENV['COMMONLOGS_ROOT_FOLDER'] || "/var/log/commonlogs".freeze
      # Legacy options
      @dest_folder = "/var/log/commonlogs".freeze unless File.directory?(@dest_folder)

      puts "STARTING WITH #{@dest_folder}"
      return @dest_folder
    end
  end
end
