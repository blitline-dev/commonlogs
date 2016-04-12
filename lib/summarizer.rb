class Summarizer
	def initialize
		@log_folder = ENV['COMMONLOGS_ROOT_FORLDER']

		fail "Must have Environment variable 'COMMONLOGS_ROOT_FORLDER' set.\n\n" unless @log_folder

	end

	def run
		puts @log_folder
	end
end

Summarizer.new.run
