require 'net/http'
require 'json'
require 'uri'
require 'awesome_print'
require 'fileutils'

require_relative '../config'
require_relative '../tags'
require_relative '../event'
require_relative '../event_config_manager'

# ------------------------------------------
# Service for sending notifications
# ------------------------------------------
class NotifierService

  def self.start
    @log_folder = ENV['COMMONLOGS_ROOT_FOLDER']
    raise "Must have Environment variable 'COMMONLOGS_ROOT_FOLDER' set. For example 'export COMMONLOGS_ROOT_FOLDER=/var/log/commonlogs'" unless @log_folder

    service = NotifierService.new
    service.perform
  end

  def perform
    LOGGER.log "Starting Notifier Service..."
    loop do
      LOGGER.log "Notifier Service Checking Logs...#{Time.now}"
      begin
        log_groups = Tags.list
        delete_files(log_groups)
      rescue => ex
        LOGGER.log "Notifier Encountered an Exception:" + ex.message
      end
      sleep(60)
    end
  end

  private

  def initialize
    @notifiers = {}
  end

  def notifier_instance(log_group, event, base_event_folder, log_file_folder)
    key = "#{log_group}#{event}"

    return @notifiers[key] if @notifiers[key]

    @notifiers[key] = Notifier.new(log_group, event, base_event_folder, log_file_folder)
    return @notifiers[key]
  end

  def delete_files(log_groups)
    log_groups.each do |log_group|
      ecm = EventConfigManager.new(log_group)
      events = ecm.events
      events.each do |event|
        base_event_folder = Tags.event_folder(log_group, event.strip)
        log_file_folder = Tags.tag_folder(log_group)
        filepath = base_event_folder + "/notification.json"
        if File.exist?(filepath)
          notifier = notifier_instance(log_group, event, base_event_folder, log_file_folder)
          notifier.run
        end
      end
    end

  end

end