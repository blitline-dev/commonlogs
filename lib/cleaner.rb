# -------------------
# Cleans out old logs
# Can be run as stand-alone
# -------------------
class Cleaner
  def initialize
    @now = Time.now.utc
    @log_folder = ENV['COMMONLOGS_ROOT_FOLDER']
    @hours_to_save = 168
    @hours_to_save = @hours_to_save.to_i
    @seconds_offset = @hours_to_save * 3600

    raise "Must have Environment variable 'COMMONLOGS_ROOT_FOLDER' set. For example 'export COMMONLOGS_ROOT_FOLDER=/var/log/commonlogs'" unless @log_folder
    raise "'COMMONLOGS_ROOT_FOLDER' is set to '#{@log_folder}' but that folder doesn't exist" unless File.exist?(@log_folder)
  end

  def run
    remove_old_files
    remove_old_cache
  end

  def get_hours_to_save
    Settings.reload
    settings = Settings.all_settings["settings"]
    settings["log_life"] || 168
    @hours_to_save = @hours_to_save.to_i
    @seconds_offset = @hours_to_save * 3600
  end

  private

  def remove_old_files
    get_hours_to_save
    Dir.glob("#{@log_folder}/**/*.log").each do |file|
      begin
        filename = File.basename(file, ".log")
        file_time = parse_filename_into_time(filename)
        File.delete(file) if file_time < @now - @seconds_offset
      rescue => ex
        puts "Error: #{ex.message}\n#{ex.backtrace[0]}"
      end
    end
  end

  def remove_old_cache
    get_hours_to_save
    Dir.glob("#{@log_folder}/**/cache/*").each do |file|
      last_modified = File.mtime(file)
      File.delete(file) if last_modified < @now - @seconds_offset
    end
  end

  def parse_filename_into_time(filename)
    parts = filename.split("-")
    if parts.length == 4
      year = parts[0].to_i
      month = parts[1].to_i
      day = parts[2].to_i
      hour = parts[3].to_i
      return Time.new(year, month, day, hour).utc
    end

    return Time.now.utc
  end

end

Cleaner.new.run
