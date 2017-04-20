require_relative 'tags'
require_relative 'util'
require_relative 'sheller'
require_relative 'cl_logger'
require_relative 'search_cache'

require 'time'

# Search handling
class Search
  include Sheller

  # Default search page size is 24 hours
  PAGE_SIZE = 4

  def initialize(tag, force_single = false)
    fail "Must have a tag for search" unless tag && tag != "-" && !tag.strip.empty?
    @tag = tag
    @now = Time.now.utc
    @now_sec = @now.to_i
    @force_single = force_single
    @search_cache = SearchCache.new(@tag) if @tag
  end

  # Search should do one of two things.
  # -- If it can find results inside
  # a "PAGE_SIZE" (or number of files to query), return those results.
  # Then let the end client request another page.
  #
  # -- Otherwise, keep searching until it finds something. Get the
  # results and return them to the user with a page number so that the
  # client knows where to page from.
  def search(text, hours_ago, p)
    data = []
    file_and_range = calculate_files_and_range(hours_ago, p)
    return unless file_and_range
    files = file_and_range[:files]
    range_start = file_and_range[:range_start]
    range_end = file_and_range[:range_end]
    data = get_search_results(data, files, range_start, range_end, text)
    if file_and_range[:filter] == true
      filter_search_result(data, file_and_range[:start_seconds], file_and_range[:end_seconds])
    end

    p += 1

    while data.empty? && range_end < files.length
      range_start = PAGE_SIZE * p
      range_end = range_start + (PAGE_SIZE - 1)
      data = get_search_results(data, files, range_start, range_end, text)
      p += 1
    end

    return { data: data, page: p - 1, has_more: range_end < files.length, count: data.length }
  end

  # Remove everything but items between timestamps
  def filter_search_result(data, start_seconds, end_seconds)
    data.reject! do |row|
      timestamp = row.to_s.split(" ")[0].split(":")[1].to_i
      timestamp.to_i < start_seconds.to_i || timestamp.to_i > end_seconds.to_i
    end
  end

  # Context just searches for the explicit line within a particular
  # file.
  def context(filename, search_text, host)
    return execute_search([filename], search_text, true, host)
  end

  # Latest is just the 'tail' functionality
  def latest(from_line_prefix = nil)
    latest_file = Tags.files(@tag).sort.delete_if(&:empty?).last

    cmd_string = "tail -n 1000 '#{latest_file}'"
    begin
      if latest_file && File.size(latest_file) == 0
        puts "guess and go"
        cmd_string = "cd #{Tags.tag_folder(@tag)} && tail -n 1000 $(ls -tp | grep -v /$ | head -2) | grep ^[0-9]"
      end
    rescue => ex
      puts "Failed to get last tailable file #{ex.message}"
    end

    results = execute_shell_command(cmd_string)
    results = trim_results(results, from_line_prefix)

    return { file: File.basename(latest_file), data: results }
  end

  private

  def calculate_files_and_range(hours_ago, p)
    results = nil

    if hours_ago.include?("-")
      start_seconds, end_seconds = hours_ago.split("-")
      start_seconds = start_seconds.to_i
      end_seconds = end_seconds.to_i
      results = calculate_files_and_range_from_timestamps(start_seconds, end_seconds, p)
    else
      results = calculate_files_and_range_form_hours_ago(hours_ago, p)
    end

    return results
  end

  def calculate_files_and_range_from_timestamps(start_seconds, end_seconds, p)
    start_seconds = start_seconds.to_i
    end_seconds = end_seconds.to_i
    files = calculate_files_from_timestamp(start_seconds, end_seconds)
    range_start = PAGE_SIZE * p
    range_end = range_start + (PAGE_SIZE - 1)
    return nil if start_seconds == 0 || end_seconds == 0

    return { files: files, range_start: range_start, range_end: range_end, filter: true, start_seconds: start_seconds, end_seconds: end_seconds }
  end

  def calculate_files_and_range_form_hours_ago(hours_ago, p)
    files = []
    guess_files = Tags.files(@tag)
    # Files may have gaps if it's sparsely logged.
    start = Time.now.utc - (hours_ago.to_i * 3600)
    0.upto(hours_ago.to_i) do |h|
      filename = Util.filename_from_time(start + (h * 3600))
      files << filename if guess_files.any? { |s| s.include?(filename) }
    end

    range_start = PAGE_SIZE * p
    range_end = range_start + (PAGE_SIZE - 1)

    return { files: files, range_start: range_start, range_end: range_end }
  end

  def calculate_files_from_timestamp(start_timestamp, end_timestamp)
    files = []
    # We need to tack on 1 to the end to make sure we get sub hours(minutes/seconds)
    # at the end.
    (start_timestamp..end_timestamp + 3600).step(3600) do |t|
      files << calculate_filename_from_timestamp(t)
    end

    return files
  end

  def calculate_hours_ago_from_timestamp(timestamp)
    (Time.now.utc - Time.at(timestamp)) / 3600
  end

  def calculate_filename_from_timestamp(timestamp)
    Time.at(timestamp).strftime("%Y-%m-%d-%H.log")
  end

  def get_search_results(data, files, range_start, range_end, text)
    sub_files = files[range_start..range_end] || []
    sub_files.map! { |f| File.basename(f) }
    data += execute_search(sub_files, text)
    return data
  end

  def execute_search(files, text, with_context = false, host = nil)
    file_paths = files.map { |f| Shellwords.shellescape(Tags.tag_folder(@tag) + "/" + f) }

    file_paths = @search_cache.check_cache_for_files(file_paths, text)
    return [] if file_paths.empty?

    if text.start_with?('/') && text.end_with?('/')
      app = "egrep"
      text = text[1..text.length - 2]
    else
      app = "fgrep"
    end

    # Force more than 1 files so that fgrep output ALWAYS prepends the filename for search
    # For example: If more than 1 files are passed to fgrep, the first entry in the result
    # is always the full path:
    # /var/log/commonlogs/blitag/2016-09-14-22.log
    # BUT, if it's only 1 file, it will only return the filename
    # 2016-09-14-22.log
    file_paths << "/dev/null" if file_paths.length < 2

    file_paths = file_paths.take(1) if @force_single

    text = text.gsub(/'/) { "'" + "\\" + "''" }

    if with_context
      cmd_string = find_context_with_host(text, file_paths, host)
    else
      cmd_string = "export LC_ALL=C && #{app} -m 10000 -ir '#{text}' #{file_paths.join(' ')}"
    end

    shell_results = execute_shell_command(cmd_string)

    if shell_results && shell_results.empty?
      @search_cache.set_skip_files(file_paths, text)
    end

    return shell_results
  end

  def find_context_with_host(text, file_paths, host)
    # Context tries progressively larger search areas to try to grab at least
    # 400 lines of context.
    # TODO: Cross file boundaries.
    # TODO: Try to balance before and after line counts
    regex = "[0-9]* [0-9]* #{host}"
    buffer = 2000
    count = 0
    tries = 0
    puts "Finding with context..."
    while tries < 4 && count < 400
      cmd_string = "export LC_ALL=C && fgrep -B #{buffer} -A 1000 '#{text}' #{file_paths.join(' ')} | egrep -c '#{regex}'"
      count = raw_shell(cmd_string).to_i
      buffer += 3000
      tries += 1
    end
    cmd_string = "export LC_ALL=C && fgrep -B #{buffer} -A 1000 '#{text}' #{file_paths.join(' ')} | egrep '#{regex}'"
    return cmd_string
  end

  # Drop results before a particular line prefix so they
  # aren't duped in the output.
  def trim_results(results, line_prefix)
    return results unless line_prefix

    results.each_with_index do |row, i|
      return results.drop(i + 1) if row.start_with? line_prefix
    end

    results
  end
end
