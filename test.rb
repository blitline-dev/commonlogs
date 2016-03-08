def last_hours_filenames(hours)
		files = []
		last_file_time = Time.now
		current_file_time = Time.now - (3600 * hours)

		while (current_file_time < last_file_time)
			files << current_file_time.strftime("%Y-%m-%d-%H.log")
			current_file_time += 3600
		end
		files << current_file_time.strftime("%Y-%m-%d-%H.log")
		return files
	end

puts last_hours_filenames(8)
