require_relative 'tags'
require_relative 'util'
require_relative 'sheller'

require 'time'
# cat 2016-03-06-14.log | awk '{ print $1}' | uniq -c
# grouping

# Search handling
class Search
	include Sheller

	# Default search page size is 24 hours
	PAGE_SIZE = 4

	def initialize(tag)
		fail "Must have a tag for search" unless tag
		@tag = tag
		@now = Time.now
		@now_sec = @now.to_i
		@rsyslog_unix_weird_offset = 24 * 3600 # 1 Full Day in Seconds
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
		files = Tags.files(@tag).sort.last(hours_ago.to_i + 1)
		data = []

		range_start = PAGE_SIZE * p
		range_end = range_start + (PAGE_SIZE - 1)
		data = get_search_results(data, files, range_start, range_end, text)
		p += 1

		while data.length == 0 && range_end < files.length
			range_start = PAGE_SIZE * p
			range_end = range_start + (PAGE_SIZE - 1)
			data = get_search_results(data, files, range_start, range_end, text)
			p += 1
		end

		return { data: data, page: p, has_more: range_end < files.length, count: data.length }
	end

	# Context just searches for the explicit line within a particular
	# file.
	def context(filename, search_text)
		return execute_search([filename], search_text, true)
	end

	# Latest is just the 'tail' functionality
	def latest(from_line_prefix = nil)
		latest_file = Tags.files(@tag).sort.last
		cmd_string = "tail -n 1000 #{latest_file}"
		results = execute_shell_command(cmd_string)
		results = trim_results(results, from_line_prefix)

		return { file: File.basename(latest_file), data: results }
	end

		private

		def get_search_results(data, files, range_start, range_end, text)
			sub_files = files[range_start..range_end]
			sub_files.map! { |f| File.basename(f) }
			data += execute_search(sub_files, text)
			return data
		end

		def execute_search(files, text, with_context = false)
			file_paths = files.map { |f| Tags.tag_folder(@tag) + "/" + f }
			if with_context
				cmd_string = "export LC_ALL=C && fgrep -A 100 -B 100 '#{text}' #{file_paths.join(' ')}"
			else
				cmd_string = "export LC_ALL=C && fgrep -m 10000 -ir '#{text}' #{file_paths.join(' ')}"
			end
			ap "Cmd string = #{cmd_string}"
			return execute_shell_command(cmd_string, with_context)
		end

		def trim_results(results, line_prefix)
			return results unless line_prefix

			results.each_with_index do |row, i|
				return results.drop(i - 500) if row.start_with? line_prefix
			end

			results
		end
end
