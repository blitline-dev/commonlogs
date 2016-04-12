require 'net/http'
require 'json'
require 'uri'
require 'awesome_print'

# ------------------------------------------
# Standalone class for sending notifications
# ------------------------------------------

class Notifier

  def initialize(log_group, event, path)
    raise "Must have a tag and event and path for Notification" unless log_group && event && path
    @log_group = log_group
    @event = event
    @path = path
  end

  def run
    begin
      last_f = last_file
      latest_line = last_line(last_f)
      last_marker = marker
      return unless latest_line != last_marker
      save_marker(latest_line)
      notify(latest_line, "#{@path}/#{last_f}")
    rescue => ex
      puts ex.message
    end
  end

  def last_line(file)
    last_line = `tail -n 1 #{@path}/#{file}`
    last_line
  end

  def last_file
    files = Dir.entries("#{@path}/.").select { |f| f.end_with?('.log') }
    files.sort!
    return files.last
  end

  def marker
    data = `cat #{@path}/.marker`
    return data
  end

  def save_marker(marker)
    File.open("#{@path}/.marker", 'w') { |f| f.write(marker) }
  end

  def notify(new_line, last_f)
    data = JSON.parse(IO.read("#{@path}/notification.json"))
    if data && data["type"]
      case data["type"]
      when "webhook" then call_webhook(data, new_line, last_f)
      else
        puts "Unknown Type for Notification Notify"
      end
    end
  end

  def call_webhook(config_data, new_line, last_f)
    type_data = config_data["type_data"]
    if type_data
      url = type_data["webhook"]
      data = build_webhook_data(new_line)
      if type_data["context"].to_s.casecmp("true") == 0
        line_prefix = build_line_prefix(new_line)
        data["context"] = build_context(line_prefix, last_f)
      end

      json_call(url, data)
    end
  end

  def build_line_prefix(line)
    sub_elements = line.split(" ")
    return sub_elements[0..2].join(" ")
  end

  def build_context(text, last_file_used)
    begin
      results = nil
      cmd_string = "export LC_ALL=C && fgrep -A 10 -B 10 '#{text}' #{last_file_used}"
      p "Running #{cmd_string}"
      Open3.popen3(cmd_string) do |_stdin, stdout, stderr, _wait_thr|
        output = stdout.read
        output_error = stderr.read
        handle_output_error(output_error)
        results = parse_results(output)
      end
      results
    rescue => ex
      puts ex.message
      puts ex.backtrace
    end
  end


  def build_webhook_data(new_line)
    {
      event: @event,
      log_name: @log_group,
      event_data: parse_event_data(new_line)
    }
  end

  def json_call(url, data)
    p "Calling #{url} with #{data.to_json}"
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Post.new(
      uri.request_uri,
      'Content-Type' => 'application/json',
      'User-Agent' => 'CommonLogs Notifier'
    )
    request.body = data.to_json
    result = http.request(request)
    return result
  end

  def parse_event_data(row)
    metadata = row[0..180]
    sub_elements = metadata.split(" ")
    date = sub_elements[0]
    seq = sub_elements[1]
    host = sub_elements[2]
    tag = sub_elements[3]
    meta_size = [date, seq, host, tag].join(" ").length + 1
    rest = row[meta_size..-1]

    {
      "timestamp" => date,
      "host" => host,
      "msg" => rest
    }
  end

  def handle_output_error(output_error)
    fail output_error if output_error && !output_error.empty?
  end

  def parse_results(results)
    rows = results.gsub("\n--\n", "").split(/\r?\n|\r/)

    if rows.length >= 1000
      rows << "\r\n WARNING: List truncated at 1000 lines..."
    end

    rows.map! { |r| parse_event_data(r) }
    return rows
  end
end

# data = {
#   name: params['name'],
#   event_name: params['event'],
#   notify_max: params['notifyMax'],
#   notify_after: params['notifyAfter'],
#   type: "webhook",
#   type_data: {
#     webhook: params['webhookUrl'],
#     context: params['context']
#   }
# }