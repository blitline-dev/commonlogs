require_relative 'config'

# App level settings
module Settings

  DEFAULT = "{\"settings\" : {}}".freeze
  SETTINGS_FILE_PATH = CommonLog::Config.destination_folder + "/settings.conf"

  def self.load_settings
    json = File.exist?(SETTINGS_FILE_PATH) ? IO.read(SETTINGS_FILE_PATH) : DEFAULT
    JSON.parse(json)
  end

  def self.save
    File.open(SETTINGS_FILE_PATH, "w") do |f|
      f.write(@settings.to_json)
    end
  end

  def self.get(key)
    @settings['settings'][key]
  end

  def self.set(key, val)
    @settings['settings'][key] = val
  end

  def self.set!(key, val)
    @settings['settings'][key] = val
    save
  end

  def self.all_settings
    @settings
  end

  @settings = load_settings
end

