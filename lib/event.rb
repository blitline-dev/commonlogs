require_relative 'tags'
require_relative 'util'
require_relative 'sheller'
require 'time'

# Event handling class
class Event
  include Sheller

  TIME_SLICE_COUNT = 180

  def initialize(tag)
    fail "Must have a tag for search" unless tag
    @tag = tag
    @now = Time.now
    @now_sec = @now.to_i

    @rsyslog_unix_weird_offset = 24 * 3600 # 1 Full Day in Seconds
    @timeslice = TIME_SLICE_COUNT
  end

  def event_and_counts(start_timestamp, end_timestamp)
    start_timestamp, end_timestamp = clean_timestamps(start_timestamp, end_timestamp)
    results = {}
    colors = {}
    event_files = Tags.all_event_files(@tag, Util.hours_ago(start_timestamp))
    p "E&C event_files=#{event_files.inspect} for #{@tag}"
    event_files.each do |file_info|
      name = file_info.event_name
      results[name] = []
      file_info.filenames.each do |file_name|
        results[name] += extract_counts(file_name, start_timestamp.to_i, end_timestamp.to_i)
      end
      colors[name] = EventConfigManager.new(@tag).get_event_color(name)
    end
    event_data = counts_from_events(results, start_timestamp, end_timestamp)
    return { st: start_timestamp, et: end_timestamp, event_data: event_data, colors: colors }
  end

  def event_list_console(event_name, start_timestamp, end_timestamp, page)
    start_timestamp, end_timestamp = clean_timestamps(start_timestamp, end_timestamp)
    results = []
    p "Getting files for #{@tag} and #{event_name}, #{Util.hours_ago(start_timestamp)}"
    event_file_names = Tags.events_files_for(@tag, event_name, Util.hours_ago(start_timestamp))
    p "event_file_names = #{event_file_names}"

    start = start_timestamp - @rsyslog_unix_weird_offset
    end_time = end_timestamp - @rsyslog_unix_weird_offset
    event_file_names.each do |filename|
      # Awk for only items past X timestamp
      cmd_string = "cat #{filename} | awk -v x=#{start} -v y=#{end_time} '$1 > x && $1 < y'"
      cmd_results = execute_shell_command(cmd_string)
      results += cmd_results.map { |r| "#{filename}: #{r}" }
    end
    start_index = page.to_i * 1000
    end_index = start_index + 1000
    results = results[start_index..end_index]
    return { event: event_name, data: results }
  end

  private

  # Based on time and timeslice, deterine which time 'bucket'
  # each count goes into.
  def bucketize(time_values, start_timestamp, end_timestamp)
    buckets = Array.new(@timeslice)
    slice = (end_timestamp - start_timestamp) / @timeslice

    time_values.each do |tv|
      index = (tv - start_timestamp) / slice
      break if tv > end_timestamp
      b = buckets[index]
      buckets[index] = b ? b + 1 : 1
    end
    return buckets
  end

  def extract_counts(filename, start_timestamp, end_timestamp)
    results = `cat #{filename} | awk '{ print $1}'`
    time = Util.measure_delta do
      results = results.split("\n")
      results.map! do |row|
        ut = row.to_i + @rsyslog_unix_weird_offset
        val = (ut >= start_timestamp && ut <= end_timestamp) ? ut : nil
        val
      end
    end
    results.compact!
    puts "Delta extract_counts = #{time}"
    return results
  end

  # Extract counts of events
  def counts_from_events(events, start_timestamp, end_timestamp)
    new_result = {}
    events.each do |k, v|
      new_array = bucketize(v, start_timestamp, end_timestamp)
      # Don't even return an empty events list
      new_result[k] = new_array unless new_array.compact.empty?
    end
    return new_result
  end

  def clean_timestamps(start_timestamp, end_timestamp)
    fail "Must have start_timestamp" unless start_timestamp
    end_timestamp = @now_sec if end_timestamp.nil?
    start_timestamp = end_timestamp - TIME_SLICE_COUNT if end_timestamp - start_timestamp < TIME_SLICE_COUNT

    return start_timestamp, end_timestamp
  end
end
