require_relative 'config'

HostInfo = Struct.new(:host, :tag, :timestamp)
# Class to handle tags and tagged streams
class Hosts
  def self.recent_data
    data = []
    begin
      filepath = CommonLog::Config.destination_folder + "/hosts"
      File.open(filepath).each do |line|
        if line && !line.empty?
          host_tag, timestamp = line.split(" ")
          host, tag = host_tag.split(":")
          data << HostInfo.new(host.strip, tag.strip, timestamp.to_i)
        end
      end

      data.sort! { |x, y| y.timestamp <=> x.timestamp }
    rescue => ex
      puts "Failed to get hosts file #{ex.message}"
    end
    return data
  end


end