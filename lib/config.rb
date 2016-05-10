module CommonLog
  class Config
    DEST_FOLDER = ENV['COMMON_LOG_FOLDER'] || "/var/log/common_log".freeze
  end
end
