require_relative '../settings'

# ------------------------------------------
# Service for removing old log files
# ------------------------------------------
class CleanerService

  def self.start
    service = CleanerService.new
    service.perform
  end

  def perform
    LOGGER.log "Starting Cleaner Service..."
    loop do
      run_cleaner
      sleep(60 * 60 * 24) # Sleep for a day
    end
  end

  private
  def run_cleaner
    begin
      if Settings.get("autodelete").to_s.casecmp("false") == 0
        LOGGER.log "Skipping Cleaner as per Settings..."
      else
        LOGGER.log "Cleaning Logs...#{Time.now}"
        `ruby lib/cleaner.rb`
      end
    rescue => ex
      LOGGER.log "Cleaner Service Excountered an Exception:" + ex.message
    end
  end

end