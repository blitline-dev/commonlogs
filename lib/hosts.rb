require_relative 'config'

HostInfo = Struct.new(:host, :tag, :timestamp)
# Class to handle tags and tagged streams
class Hosts
  def self.recent_data
    filepath = CommonLog::Config.destination_folder + "/hosts"
    data = []
    File.open(filepath).each do |line|
      if line && !line.empty?
        host_tag, timestamp = line.split(" ")
        host, tag = host_tag.split(":")
        data << HostInfo.new(host.strip, tag.strip, timestamp.to_i)
      end
    end
    return data
  end


end