
require 'fileutils'
#----------------
# AWS CLI Handler
#----------------
class Aws
  AWS_FOLDER = "#{Dir.home}/.aws".freeze
  AWS_CRED_FILE = "#{AWS_FOLDER}/credentials".freeze
  AWS_CONFIG_FILE = "#{AWS_FOLDER}/config".freeze

  def initialize
    @iam_key = Settings.get("iam_key")
    @iam_secret = Settings.get("iam_secret")
    @bucket = Settings.get("bucket")
    @location = Settings.get("location")
    @key_prefix = Settings.get("key_prefix") || ""
    @location = "us-east-1" if @location.nil? || @location.empty?
    setup if active?
  end

  def active?
    @iam_key && @iam_secret && @bucket
  end

  def sync_files(filepaths)
    command = build_command(filepaths)
    LOGGER.log command
    output = ""
    Open3.popen3(command) do |_stdin, stdout, stderr, _wait_thr|
      output = stdout.read
      output_error = stderr.read
      handle_output_error(output_error)
    end
    LOGGER.log output
  end

  private

  def build_command(filepaths)
    command = "aws s3 cp #{CommonLog::Config.destination_folder}/ s3://#{@bucket}/#{@key_prefix} --recursive --exclude \"*\" "
    includes = []
    filepaths.each do |filepath|
      includes << "--include \"#{filepath}\""
    end
    includes << "--region #{@location}"
    command += includes.join(" ")
    command
  end

  def setup
    verify_or_create_credentials
  end

  def verify_or_create_credentials
    # Make sure folder exists
    FileUtils.mkdir_p AWS_FOLDER

    File.open(AWS_CRED_FILE, "w") do |f|
      f.write(credential_file_data)
    end

    # Make sure folder exists
    FileUtils.mkdir_p AWS_FOLDER
    File.open(AWS_CONFIG_FILE, "w") do |f|
      f.write(config_file_data)
    end
  end

  def handle_output_error(error_text)
    LOGGER.log "Error with AWS Upload" + error_text unless error_text.to_s.empty?
  end

  def credential_file_data
    "[default]\naws_access_key_id=#{@iam_key}\naws_secret_access_key=#{@iam_secret}"
  end

  def config_file_data
    "[default]\nregion=us-west-2\noutput=json"
  end

end


