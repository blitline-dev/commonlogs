require_relative 'config'

HostInfo = Struct.new(:host, :tag, :timestamp, :cpu, :memory, :load, :disk)
CollectDInfo = Struct.new(:host, :tag, :data, :timestamp, :local_timestamp)

# Class to handle tags and tagged streams
class Hosts
  def self.recent_data
    data = []
    begin
      stats = collectd_stats
      filepath = CommonLog::Config.destination_folder + "/hosts"
      File.open(filepath).each do |line|
        if line && !line.empty?
          host_tag, timestamp = line.split(" ")
          host, tag = host_tag.split(":")
          data << build_host_info(host.strip, tag.strip, timestamp, stats)
        end
      end

      data.sort! { |x, y| y.timestamp <=> x.timestamp }
    rescue => ex
      puts "Failed to get hosts file #{ex.message}"
    end
    return data
  end

  def self.map_collectd_keys_to_host(stats)
    keys = stats.keys
    result_hash = {}
    keys.each do |key|
      host, tag = key.split("::")
      data = stats[key]
      result_hash[host] = [] if result_hash[host].nil?
      result_hash[host] << data
      host += "_ec2_internal"
      result_hash[host] = [] if result_hash[host].nil?
      result_hash[host] << data
    end
    return result_hash
  end

  def self.build_host_info(host, tag, timestamp, stats)
    return HostInfo.new(host, tag, timestamp.to_i) if stats.empty? || stats[host].nil? || stats[host].empty?
    stat_hash = build_stat_hash(stats[host])
    memory = determine_memory(stat_hash)
    cpu = determine_cpu(stat_hash)
    load = determine_load(stat_hash)
    return HostInfo.new(host, tag, timestamp.to_i, cpu, memory, load)
  end

  def self.build_stat_hash(stat_array)
    stat_hash = {}
    stat_array.each do |stat|
      stat_hash[stat.tag] = stat
    end
    stat_hash
  end

  def self.determine_memory(stat_hash)
    used = stat_hash["memory.memory-used"].data.to_i
    buffered = stat_hash["memory.memory-buffered"].data.to_i
    cached = stat_hash["memory.memory-cached"].data.to_i
    free = stat_hash["memory.memory-free"].data.to_i
    
    total = used + buffered + buffered + free
    return nil if total.zero?

    percent = (used.to_f / total.to_f) * 100
    return percent.round(2)
  end

  def self.determine_cpu(stat_hash)
    idle = stat_hash["cpu-0.cpu-idle"] ? stat_hash["cpu-0.cpu-idle"].data : nil
    return nil if idle.nil? || idle.empty?

    percent = 100.0 - idle.to_f
    return percent.round(2)
  end

  def self.determine_load(stat_hash)
    load = stat_hash["load.load.midterm"].data.to_f
    return nil if load.nil? 

    return load
  end

  def self.collectd_stats
    host_data = {}
    begin
      filepath = CommonLog::Config.destination_folder + "/collectd"
      return host_data unless File.exist?(filepath)
      File.open(filepath).each do |line|
        if line && !line.empty?
          host_tag, local_timestamp = line.split(" ")
          host, tag, data, timestamp = host_tag.split("::")
          host = host.strip
          tag = tag.strip
          host_data["#{host}::#{tag}"] = CollectDInfo.new(host, tag, data, timestamp.to_i) unless host_data["#{host}::#{tag}"]
        end
      end
    rescue => ex
      puts "Failed to get collectd file #{ex.message}"
    end
    return map_collectd_keys_to_host(host_data)
  end
end