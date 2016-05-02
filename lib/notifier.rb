require 'net/http'
require 'json'
require 'uri'
require 'awesome_print'
require_relative 'cron/cron_service'

class Notifier

  def initialize(log_group, event, path, log_file_folder)
    raise "Must have a tag and event and path for Notification" unless log_group && event && path
    @log_group = log_group
    @event = event
    @path = path
    @log_file_folder = log_file_folder

    @config = JSON.parse(IO.read("#{@path}/notification.json"))
    count = @config["notify_max"]

    cron_function = lambda do |data|
      new_line = data[:latest_line]
      last_f = data[:last_file]
      notify(new_line, last_f)
    end

    args = {
      name: log_group + event,
      max_count: count,
      period: 3_600,
      function: cron_function
    }

    @cron_service = CronService.new(args)
  end

  def run
    begin
      last_f = last_file
      latest_line = last_line(last_f)
      last_marker = marker(1)
      return nil unless latest_line != last_marker
      save_marker(latest_line)
      @cron_service.notify(latest_line: latest_line, last_file: "#{@path}/#{last_f}")
    rescue => ex
      puts ex.message
      puts ex.backtrace
    end
  end

  def notify(new_line, last_f)
    data = JSON.parse(IO.read("#{@path}/notification.json"))

    if data && data["ntype"]
      case data["ntype"]
      when "webhook" then call_webhook(data, new_line, last_f)
      when "slack" then call_slack(data, new_line, last_f)
      else
        puts "Unknown Type for Notification Notify"
      end
    end
  end

  def last_line(file)
    return "" unless  File.exist?("#{@path}/#{file}")

    last_line = `tail -n 1 #{@path}/#{file}`
    last_line
  end

  def last_file
    files = Dir.entries("#{@path}/.").select { |f| f.end_with?('.log') }
    files.sort!
    return files.last
  end

  def original_log_file
    @log_file_folder + "/" + last_file
  end

  def marker(count)
    return "" unless  File.exist?("#{@path}/.marker")

    return `tail -n #{count} #{@path}/.marker`
  end

  def save_marker(marker)
    File.open("#{@path}/.marker", 'w') { |f| f.write(marker) }
  end

  def call_slack(config_data, new_line, last_f)
    type_data = config_data["type_data"]
    return unless type_data

    slack_webhook_url = type_data["slack_webhook"]
    context = nil
    if type_data["context"].to_s.casecmp("true") == 0
      line_prefix = build_line_prefix(new_line)
      context = build_context(line_prefix, last_f)
      context = context.map do |r|
        r["msg"][0..80]
      end
    end
    data = build_slack_webhook_data(@event, context.join("\n"))
    json_call(slack_webhook_url, data)
  end

  def call_webhook(config_data, new_line, last_f)
    type_data = config_data["type_data"]
    return unless type_data

    url = type_data["webhook"]
    data = build_webhook_data(new_line)
    if type_data["context"].to_s.casecmp("true") == 0
      line_prefix = build_line_prefix(new_line)
      data["context"] = build_context(line_prefix, last_f)
    end

    json_call(url, data)
  end

  def build_line_prefix(line)
    sub_elements = line.split(" ")
    return sub_elements[0..2].join(" ")
  end

  def build_context(text, last_file_used)
    begin
      results = nil
      cmd_string = "export LC_ALL=C && fgrep -A 5 -B 5 '#{text}' #{original_log_file}"
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

  def build_slack_webhook_data(event_name, context)
    {
      attachments: [
        {
          fallback: "CommonLogs Notification [#{event_name}]",
          pretext: "CommonLogs Notification [#{event_name}]",
          color: "#6164C1",
          fields: [
            {
              title: "Context",
              value: context.to_s,
              short: false
            }
          ]
        }
      ]
    }
  end

  def json_call(url, data)
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == "https")

    request = Net::HTTP::Post.new(
      uri.request_uri,
      'Content-Type' => 'application/json'
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