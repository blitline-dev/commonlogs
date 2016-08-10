require 'fileutils'
require_relative 'tags'
require_relative 'util'
require_relative 'sheller'

# Class for managing rsyslog config files associated with
# events.
# -------------------------------------
# Template Folder (Templates $Included in rsyslog)
#
# rsyslog.tl
#   |
#   |---- <GROUP_NAME>.conf
#   |---- <GROUP_NAME>.d
#       |
#       |---- <SEACH_TERM>.conf
#
# Log Config (Search terms to make events of)
#
# rsyslog.rl
#   |
#   |---- <GROUP_NAME>.conf
#   |---- <GROUP_NAME>.d
#       |
#       | ---- <SEARCH_TERM>.conf
# -------------------------------------
class EventConfigManager
  include Sheller

  EVENT_FOLDER_NAME = "events".freeze
  SYSLOG_ROOT = CommonLog::Config.destination_folder + "/.config_includes"
  TEMPLATE_FOLDER = "rsyslog.tl".freeze
  FILTER_FOLDER = "rsyslog.rl".freeze

  def initialize(name)
    assure_syslog_root
    fail "Log Group must be specified!" unless name
    @name = name
  end

  def delete_all_events
    events.each do |event|
      delete!(event)
    end
  end

  def delete!(event)
    full_folder = full_event_folder(event)
    begin
      delete_syslog_template(event)
      delete_syslog_filter(event)
      FileUtils.rm_rf(full_folder)
      flag_for_rsyslog_restart
    rescue => ex
      LOGGER.log "Failed to delete #{full_folder}, EX: #{ex.message}"
    end
  end

  def create!(event, event_data)
    full_folder = full_event_folder(event)
    Util.cl_mkdir_p full_folder
    create_prefs_file(event_data)
    create_syslog_template(event)
    create_syslog_filter(event, event_data["search"])
    flag_for_rsyslog_restart
  end

  def get_events_preferences(name)
    prefs = {}
    event_folders = events.delete_if { |x| x[0] == '.' }
    event_folders.each do |f|
      prefs[f] = get_event_preference(name, f)
    end
    prefs
  end

  def get_event_color(event)
    event_prefs = get_event_preference(@name, event)
    return event_prefs["color"] || "#ffffff"
  end

  def get_event_preference(name, event)
    prefs_file = Tags.event_folder(name, event) + "/" + "prefs.json"
    s = File.exist?(prefs_file) ? IO.read(prefs_file) : "{\"event_name\" : \"#{event}\"}"

    data = JSON.parse(s)
    return data
  end

  def events
    assure_events_folderpath
    Dir.entries(CommonLog::Config.destination_folder + '/' + @name + '/' + EVENT_FOLDER_NAME).select { |f| !File.directory?(f) }.delete_if { |x| x[0] == '.' }
  end

  private

  def events_folder
    CommonLog::Config.destination_folder + '/' + @name + '/' + EVENT_FOLDER_NAME
  end

  def template_include_filepath
    "#{SYSLOG_ROOT}/#{TEMPLATE_FOLDER}/#{@name}.conf"
  end

  def filter_include_filepath
    "#{SYSLOG_ROOT}/#{FILTER_FOLDER}/#{@name}.conf"
  end

  def template_filepath(event)
    "#{SYSLOG_ROOT}/#{TEMPLATE_FOLDER}/#{@name}.d/#{event}.conf"
  end

  def filter_filepath(event)
    "#{SYSLOG_ROOT}/#{FILTER_FOLDER}/#{@name}.d/#{event}.conf"
  end

  def filter_folderpath
    "#{SYSLOG_ROOT}/#{FILTER_FOLDER}/#{@name}.d/"
  end

  def template_folderpath
    "#{SYSLOG_ROOT}/#{TEMPLATE_FOLDER}/#{@name}.d/"
  end

  def full_event_folder(event)
    Tags.event_folder(@name, event.strip)
  end

  def flag_for_rsyslog_restart
    `echo 'true' > #{SYSLOG_ROOT}/restart_rsyslog`
  end

  def delete_syslog_template(event)
    FileUtils.rm_rf(template_filepath(event))
  end

  def delete_syslog_filter(event)
    FileUtils.rm_rf(filter_filepath(event))
  end

  def assure_events_folderpath
    dirname = events_folder
    Util.cl_mkdir_p(dirname) unless File.directory?(dirname)
  end

  def assure_name_folderpath(_event)
    dirname = filter_folderpath
    Util.cl_mkdir_p(dirname) unless File.directory?(dirname)
    dirname = template_folderpath
    Util.cl_mkdir_p(dirname) unless File.directory?(dirname)
    assure_syslog_filter_include_file
    assure_syslog_template_include_file
  end

  def create_prefs_file(event_data)
    filepath = full_event_folder(event_data["event_name"]) + "/prefs.json"
    File.open(filepath, "w") do |f|
      f.write(event_data.to_json)
    end
  end

  def assure_syslog_root
    Util.cl_mkdir_p(SYSLOG_ROOT) unless File.directory?(SYSLOG_ROOT)
  end

  def assure_syslog_filter_include_file
    filepath = filter_include_filepath
    data = %{
if ($syslogtag == '#{@name}') then {
  $IncludeConfig  #{SYSLOG_ROOT}/rsyslog.rl/#{@name}.d/*
}
    }
    File.write(filepath, data) unless File.exist?(filepath)
  end

  def assure_syslog_template_include_file
    filepath = template_include_filepath
    data = %{
$IncludeConfig #{SYSLOG_ROOT}/rsyslog.tl/#{@name}.d/*
    }
    File.write(filepath, data) unless File.exist?(filepath)
  end

  def create_syslog_template(event)
    assure_name_folderpath(event)
    filepath = template_filepath(event)
    data = %{
template (name="DynFile_#{event}" type="string" string="#{CommonLog::Config.destination_folder}/%syslogtag%/events/#{event}/%$now%-%$hour%.log")
    }
    File.write(filepath, data)
  end

  def create_syslog_filter(event, search)
    assure_name_folderpath(event)
    filepath = filter_filepath(event)

    data = %{
if ($msg contains '#{search}') then {
action(template="FileFormat" type="omfile" dynaFile="DynFile_#{event}" FileOwner="syslog" FileGroup="syslog" DirOwner="syslog" DirGroup="syslog" DirCreateMode="0770" FileCreateMode="0644")
}
    }

    File.write(filepath, data)
  end
end


