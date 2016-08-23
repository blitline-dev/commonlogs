require_relative 'config'

EventFiles = Struct.new(:tag, :event_name, :filenames)
# Class to handle tags and tagged streams
class Tags
  EVENT_FOLDER_NAME = "events".freeze

  def self.delete(tag)
    folder = tag_folder(tag)
    event_config_manager = EventConfigManager.new(tag)
    event_config_manager.delete!(tag)
    FileUtils.rm_rf(folder)
  end

  def self.file_stats
    stats = {}
    list_of_dirs = list
    list_of_dirs.each do |dir|
      full_path = CommonLog::Config.destination_folder + "/" + dir
      full_events_path = full_path + '/events'
      dir_size = `du -hs '#{full_path}' | awk '{ print $1 }'`.to_s.strip!
      event_size = `du -hs '#{full_events_path}' | awk '{ print $1 }'`.to_s.strip!
      stats[dir] = { dir_size: dir_size, event_size: event_size }
    end
    stats
  end

  def self.drive_space
    drives = []
    begin
      v = `df -H`
      v.lines.each do |l|
        data = l.split(/ {2}+/)
        output = {}
        output[:drive] = data[0].to_s.strip
        output[:size] = data[1].to_s.strip
        output[:available] = data[3].to_s.strip
        drives << output
      end
    rescue => ex
      LOGGER.log ex
    end
    return drives
  end

  def self.list
    results = Dir.entries(CommonLog::Config.destination_folder).select do |f|
      File.directory?(CommonLog::Config.destination_folder + "/" + f) unless f.start_with?(".")
    end
    results.sort!
  end

  def self.files(tag)
    Dir[CommonLog::Config.destination_folder + '/' + tag + '/*.log']
  end

  def self.event_files(tag, event)
    Dir[event_folder(tag, event) + '/*.log']
  end

  def self.event_folder(tag, event)
    CommonLog::Config.destination_folder + '/' + tag + '/' + EVENT_FOLDER_NAME + '/' + event
  end

  def self.tag_folder(tag)
    CommonLog::Config.destination_folder + '/' + tag
  end

  # Get list of all possible event files
  def self.events_files_for(tag, event, last_hours)
    possible_filenames = last_hours_filenames(last_hours).map { |f| event_folder(tag, event) + "/" + f }
    p "Possible"
    ap possible_filenames
    actual_filenames = event_files(tag, event)
    p "Actual"
    ap actual_filenames
    final = possible_filenames & actual_filenames
    return final
  end

  def self.all_event_files(tag, last_hours)
    event_config_manager = EventConfigManager.new(tag)
    event_names = event_config_manager.events
    events = event_names.map { |e| EventFiles.new(tag, e, events_files_for(tag, e, last_hours)) }
    events
  end

  def self.full_path(tag, filename)
    files(tag).each do |file|
      return file if file.include?(filename)
    end
  end

  def self.last_hours_filenames(hours)
    files = []
    last_file_time = Time.now.utc
    current_file_time = Time.now.utc - (3600 * hours)

    while current_file_time < last_file_time
      files << current_file_time.strftime("%Y-%m-%d-%H.log")
      current_file_time += 3600
    end
    files << current_file_time.strftime("%Y-%m-%d-%H.log")
    return files
  end

end
