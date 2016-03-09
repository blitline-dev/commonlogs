require_relative 'tags'
require_relative 'util'
require 'open3'
require 'time'
# cat 2016-03-06-14.log | awk '{ print $1}' | uniq -c
# grouping

# Search handling
class Search
	MAX_LIST_SIZE = 50_000
	TIME_SLICE_COUNT = 180

	def initialize(tag)
		fail "Must have a tag for search" unless tag
		@tag = tag
	end

	def search(text, hours_ago = 1)
		files = Tags.files(@tag).sort.last(hours_ago.to_i + 1)
		files.map! { |f| File.basename(f) }
		return { data: execute_search(files, text) }
	end

	def context(filename, search_text)
		return execute_search([filename], search_text, true)
	end

	def latest(from_line_prefix = nil)
		latest_file = Tags.files(@tag).sort.last
		cmd_string = "tail -n 1000 #{latest_file}"
		results = execute_shell_command(cmd_string)
		results = trim_results(results, from_line_prefix)

		return { file: File.basename(latest_file), data: results }
	end

	def event_list_console(event_name, hours, page = 0)
		results = []
		event_file_names = Tags.events_for(@tag, event_name, hours)
		event_file_names.each do |filename|
			cmd_string = "cat #{event_file_names.join(' ')}"
			cmd_results = execute_shell_command(cmd_string)
			results += cmd_results.map { |r| "#{filename}: #{r}" }
		end
		start_index = page * 1000
		end_index = start_index + 1000
		results = results[start_index..end_index]
		return { event: event_name, data: results }
	end

	def events(hours_ago)
		fail "Must have hours offset" unless hours_ago
		results = {}
		return_value = nil
		time = Util.measure_delta do
			event_files = Tags.all_event_files(@tag, hours_ago)
			event_files.each do |file_info|
				name = file_info.event_name
				results[name] = []
				file_info.filenames.each do |file_name|
					results[name] += extract_counts(file_name)
				end
			end
			return_value = counts_from_events(results, hours_ago)
		end
		puts "Delta events = #{time}"
		return_value
	end

	private
		# Based on time and timeslice, deterine which time 'bucket'
		# each count goes into.
		def bucketize(time_values, hours)
			now = Time.now
			puts "hours #{hours}"
			buckets = Array.new(TIME_SLICE_COUNT)
			start = (now - (3600 * hours)).to_i
			end_time = now.to_i
			slice = (end_time - start) / TIME_SLICE_COUNT

			time_values.each do |tv|
				index = (tv - start) / slice
				if tv > end_time
					puts "!!!!! tv > end_time #{tv} > #{end_time}"
					break
				end
				b = buckets[index]
				buckets[index] = b ? b + 1 : 0
			end
			return buckets
		end

		def extract_counts(filename)
			results = `cat #{filename} | awk '{ print $1}'`
			time = Util.measure_delta do
				results = results.split("\n")
				results.map! { |row| row.to_i + 86_400 }
			end
			puts "Delta extract_counts = #{time}"
			return results
		end

		# Extract counts of events
		def counts_from_events(events, hours)
			new_result = {}
			events.each do |k, v|
				new_array = bucketize(v, hours)
				# Don't even return an empty events list
				new_result[k] = new_array unless new_array.compact.length == 0
			end
			return new_result
		end
		
		def execute_search(files, text, with_context = false)
			file_paths = files.map { |f| tag_folder + "/" + f }
			if with_context
				cmd_string = "export LC_ALL=C && fgrep -A 100 -B 100 '#{text}' #{file_paths.join(' ')}"
			else
				cmd_string = "export LC_ALL=C && fgrep -m 50000 -ir '#{text}' #{file_paths.join(' ')}"
			end
			ap "Cmd string = #{cmd_string}"
			return execute_shell_command(cmd_string, with_context)
		end

		def execute_shell_command(cmd_string, with_context = false)
			results = nil
			start_time = Time.now.to_i
			p "Start cmd"
			Open3.popen3(cmd_string) do |_stdin, stdout, stderr, _wait_thr|
				output = stdout.read
				output_error = stderr.read
				fail output_error if output_error && !output_error.empty?
				results = parse_results(output, with_context)
			end
			end_time = Time.now.to_i
			puts "Finished after: #{end_time - start_time} seconds"

			return results
		end

		def parse_results(results, _wait_thrh_context)
			rows = results.gsub("\n--\n", "").split(/\r?\n|\r/)

			if rows.length >= MAX_LIST_SIZE
				rows << "\r\n WARNING: List truncated at #{MAX_LIST_SIZE} lines..."
			end

			return rows
		end

		def tag_folder
			return RocketLog::Config::DEST_FOLDER + "/" + @tag
		end

		def trim_results(results, line_prefix)
			return results unless line_prefix

			results.each_with_index do |row, i|
				return results.drop(i - 500) if row.start_with? line_prefix
			end

			results
		end
end
