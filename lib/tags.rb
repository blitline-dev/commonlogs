require_relative 'config'

EventFiles = Struct.new(:tag, :event_name, :filenames)
# Class to handle tags and tagged streams
class Tags
  EVENT_FOLDER_NAME = "events".freeze

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
    actual_filenames = event_files(tag, event)

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
    last_file_time = Time.now
    current_file_time = Time.now - (3600 * hours)

    while current_file_time < last_file_time
      files << current_file_time.strftime("%Y-%m-%d-%H.log")
      current_file_time += 3600
    end
    files << current_file_time.strftime("%Y-%m-%d-%H.log")
    return files
  end

end
