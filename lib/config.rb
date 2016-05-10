module CommonLog
  class Config
    DEST_FOLDER = ENV['COMMON_LOG_FOLDER'] || "/var/log/commonlog".freeze
  end
end
