require 'fileutils'
require_relative 'tags'
require_relative 'util'
require_relative 'sheller'
# Class for managing rsyslog config files associated with
# events.

class EventConfigManager
	include Sheller

	EVENT_FOLDER_NAME = "events"
	SYSLOG_ROOT = "/etc/rsyslog.d"
	TEMPLATE_FOLDER = "rsyslog.tl"
	FILTER_FOLDER = "rsyslog.rl"

	def initialize(name)
		fail "Log Group must be specified!" unless name
		@name = name
	end

	def delete!(event)
		full_folder = full_event_folder(event)
		begin
			delete_syslog_template(event)
			delete_syslog_filter(event)
			FileUtils.rm_rf(full_folder)
			flag_for_rsyslog_restart
		rescue => ex
			puts "Failed to delete #{full_folder}, EX: #{ex.message}"
		end
	end

	def create!(event, event_data)
		full_folder = full_event_folder(event)
		FileUtils.mkdir_p full_folder
		create_prefs_file(event_data)
		create_syslog_template(event)
		create_syslog_filter(event, event_data["search"])
		flag_for_rsyslog_restart
	end

	def get_events_preferences(name)
		prefs = {}
		event_folders = events.delete_if { |x| x[0] == '.' }
		event_folders.each do |f|
			prefs_file = Tags.event_folder(name, f) + "/" + "prefs.json"
			if File.exist?(prefs_file)
				s = IO.read(prefs_file)
			else
				s = "{\"event_name\" : \"#{f}\"}"
			end
			data = JSON.parse(s)
			prefs[f] = data
		end
		prefs
	end

	def events
		assure_events_folderpath
		Dir.entries(RocketLog::Config::DEST_FOLDER + '/' + @tag + '/' + EVENT_FOLDER_NAME).select { |f| !File.directory?(f) }.delete_if { |x| x[0] == '.' }
	end


		private

		def events_folder
			RocketLog::Config::DEST_FOLDER + '/' + @tag + '/' + EVENT_FOLDER_NAME
		end

		def template_filepath(event)
			"#{SYSLOG_ROOT}/#{TEMPLATE_FOLDER}/#{@name}.d/#{event}"
		end

		def filter_filepath(event)
			"#{SYSLOG_ROOT}/#{FILTER_FOLDER}/#{@name}.d/#{event}"
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
			`echo 'true' > /tmp/restart_rsyslog`
		end

		def delete_syslog_template(event)
			FileUtils.rm_rf(template_filepath(event))
		end

		def delete_syslog_filter(event)
			FileUtils.rm_rf(filter_filepath(event))
		end

		def assure_events_folderpath
			dirname = events_folder
			FileUtils.mkdir_p(dirname) unless File.directory?(dirname)
		end

		def assure_name_folderpath
			dirname = filter_folderpath
			puts "assure_filter_folderpath #{dirname}"
			FileUtils.mkdir_p(dirname) unless File.directory?(dirname)
			dirname = template_folderpath
			puts "assure_template_folderpath #{dirname}"
			FileUtils.mkdir_p(dirname) unless File.directory?(dirname)
		end

		def create_prefs_file(event_data)
			filepath = full_event_folder(event_data["event_name"]) + "/prefs.json"
			puts "Wriign to #{filepath} #{event_data.inspect}"
			File.open(filepath, "w") do |f|
			  f.write(event_data.to_json)
			end
		end

		def create_syslog_template(event)
			assure_name_folderpath
			filepath = template_filepath(event)
			puts "create_syslog_template #{filepath}"
			data = "template (name=\"DynFile_#{event}\" type=\"string\" string=\"/var/log/rocket_log/%syslogtag%/events/#{event}/%$now%-%$hour%.log\")"
			File.write(filepath, data)
		end

		def create_syslog_filter(event, search)
			assure_name_folderpath
			filepath = filter_filepath(event)
			puts "create_syslog_filter #{filepath}"

			data = %{
if ($msg contains '#{search}') then {
	action(template="FileFormat" type="omfile" dynaFile="DynFile_#{event}")
}
			}

			File.write(filepath, data)
		end
end
