require_relative '../tags'
require_relative '../aws'

# ------------------------------------------
# Service for backing up to AWS
# ------------------------------------------
class AwsService
  ONE_DAY = 60 * 60 * 24

  def initialize
  end

  def self.start
    service = AwsService.new
    service.perform
  end

  def perform
    @log_folder = ENV['COMMONLOGS_ROOT_FOLDER']
    raise "Must have Environment variable 'COMMONLOGS_ROOT_FOLDER' set. For example 'export COMMONLOGS_ROOT_FOLDER=/var/log/commonlogs'" unless @log_folder

    LOGGER.log "Starting Aws Service..."
    loop do
      begin
        do_sync
      rescue => ex
        LOGGER.log ex
      end
      sleep(60 * 60 * 24) # Sleep for a day
    end
  end

  def do_sync
    aws_instance = Aws.new
    if aws_instance.active?
      LOGGER.log "Aws: Backing Up Logs...#{Time.now.utc}"
      folder_files = find_yesterdays_files(list_of_all_files)
      all_files = build_array_of_files(folder_files)
      ap all_files

      aws_instance.sync_files(all_files)
    end
  end

  def build_array_of_files(folder_files)
    all_files = []
    folder_files.each do |folder, files|
      files.each do |file|
        all_files << File.join(file)
      end
    end
    return all_files
  end

  def list_of_all_files
    folders = Tags.list
    folder_files = {}
    folders.each do |name|
      folder_files[name] = Tags.files(name)
    end
    return folder_files
  end

  def find_yesterdays_files(folder_files)
    current_time = (Time.now - ONE_DAY).utc
    day_name_base = current_time.strftime("%Y-%m-%d")
    folder_files.each do |_folder, files|
      files.select! { |f| File.basename(f).start_with?(day_name_base) }
    end
  end


end