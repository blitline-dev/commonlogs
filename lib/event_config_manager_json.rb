require 'fileutils'
require_relative 'tags'
require_relative 'util'
require_relative 'sheller'

# Config Format (events.json):
# {
#  "events" : {           # <-- Root node
#    "shake@nat" : {      # <-- Log Name
#       "thou_finder" : { # <-- Individual Events with data
#           "color" : "red",
#           "event_name" : "thou_finder",
#           "find" : "thou",
#           "description" : "description"
#       }
#     }
#   }
# }


# Handles the configuration of the server to copy events into sub-folders
class EventConfigManager
  include Sheller

  EVENT_FOLDER_NAME = "events".freeze
  SYSLOG_ROOT = CommonLog::Config.destination_folder
  EVENTS_JSON_ROOT = CommonLog::Config.destination_folder + "/events.json"
  TEMPLATE_FOLDER = "rsyslog.tl".freeze
  FILTER_FOLDER = "rsyslog.rl".freeze

  def initialize(name)
    @name = name
    assure_events_json_root
    assure_events_folder
    fail "Log Group must be specified!" unless name
  end

  def delete_all
    data = load_events
    return unless data
    data.delete(@name)
    save_events(data)
  end

  def delete!(event)
    data = load_events
    return unless data[@name]

    data[@name].delete(event)
    save_events(data)
    delete_folder(event)
  end

  def delete_folder(event)
    folder = single_event_folder(event)
    FileUtils.rm_rf(folder) if File.directory?(folder)
  end

  def create!(event_data)
    assure_new_event_folderpath(event_data["event_name"])

    data = load_events
    data[@name] = {} if data[@name].nil?
    data[@name][event_data["event_name"]] = map_data(event_data)
    save_events(data)
  end

  def load_events
    s = IO.read(EVENTS_JSON_ROOT)
    JSON.parse(s)["events"]
  end

  def save_events(data)
    save_data = { events: data }
    File.write(EVENTS_JSON_ROOT, save_data.to_json)
  end

  def map_data(event_data)
    base = {}
    base["find"] = event_data["search"].nil? ? event_data["find"] : event_data["search"]
    base["color"] = event_data["color"]
    base["description"] = event_data["description"]
    base["event_name"] = event_data["event_name"]
    return base
  end

  def get_events_preferences(name)
    data = load_events
    return data[name] || {}
  end

  def get_event_color(event)
    event_prefs = get_event_preference(@name, event)
    return unless event_prefs
    return event_prefs["color"] || "#ffffff"
  end

  def get_event_preference(name, event_name)
    s = IO.read(EVENTS_JSON_ROOT)
    data = JSON.parse(s)["events"]
    events_for_name = data[name] || {}
    return events_for_name[event_name]
  end

  def events
    Dir.entries(CommonLog::Config.destination_folder + '/' + @name + '/' + EVENT_FOLDER_NAME).select { |f| !File.directory?(f) }.delete_if { |x| x[0] == '.' }
  end

  private

  def assure_new_event_folderpath(event_name)
    assure_events_folder
    dirname = single_event_folder(event_name)
    Util.cl_mkdir_p(dirname) unless File.directory?(dirname)
    dirname
  end

  def assure_events_folder
    dirname = events_folder
    Util.cl_mkdir_p(dirname) unless File.directory?(dirname)
  end

  def events_folder
    CommonLog::Config.destination_folder + '/' + @name + '/' + EVENT_FOLDER_NAME
  end

  def single_event_folder(event)
    events_folder + "/" + event
  end

  def full_event_folder(event)
    Tags.event_folder(@name, event.strip)
  end

  def assure_events_json_root
    filepath = EVENTS_JSON_ROOT
    data = "{ \"events\" : {} }"
    File.write(filepath, data) unless File.exist?(filepath)
  end

end


