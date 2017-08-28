require "socket"
require 'rubygems'

begin
  require 'forever'
rescue LoadError
  puts "Failed to load gem foreverb, please run 'gem install foreverb usagewatch'"
  exit 1
end

begin
  require 'usagewatch_ext'
  @usw = Usagewatch
rescue LoadError
  begin
    require 'usagewatch'
    
  rescue LoadError
    puts "Failed to load gem usagewatch_ext, please run 'gem install foreverb usagewatch'"
    exit 1
  end
end

if ENV["CL_HOST"].nil?
  puts "You must set environment variable 'CL_HOST' to your commonlogs host server before starting this service"
  exit 1
end

def start
  @usw = Usagewatch
  puts "usagewatch #{Usagewatch}"
  host = ENV["CL_HOST"].to_s.strip
  port = ENV["CL_HOST_PORT"] || 6768
  hostname = `hostname`.strip
  s = TCPSocket.open(host, port.to_i)
  loop do
    begin
      disk, cpu, mem = get_stats
      send_strings = []
      send_strings << "collectd.#{hostname}.aggregation-cpu-average.cpu-idle #{100.0 - cpu} #{Time.now.to_i}"
      send_strings << "collectd.#{hostname}.memory_usage.percentage #{mem} #{Time.now.to_i}"
      send_strings << "collectd.#{hostname}.disk_usage.percentage #{disk} #{Time.now.to_i}"
      send_strings.each do |string|
        s.puts string
      end
      sleep(30)
    rescue => ex
      s.close
      s = TCPSocket.open(host, port.to_i)
      `logger "cl_collectd sender... #{ex.message}"`
      sleep(10)
      retry
    end
  end
end

def get_stats
  output = `df -hBM | sort -k2 | tail -n 1 | awk '{print $5}'`
  disk = output.strip.tr('%', '').to_i
  cpu = @usw.uw_cpuused.to_f
  mem = @usw.uw_memused.to_i
  [disk, cpu, mem]
end

Forever.run do
  log  "/tmp/collector.log"

  on_error do |e|
    `logger 'commonlogs collector failed with exeption #{e.message}'`
  end

   before :all do
    start
  end
end