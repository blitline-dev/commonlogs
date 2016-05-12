require 'nokogiri'
require 'fileutils'

class Util

  def self.measure_delta
    start_time = Time.now.to_f
    yield
    end_time = Time.now.to_f
    return end_time - start_time
  end

  def self.suid(length = 16)
    prefix = rand(10).to_s
    random_string = prefix + ::SecureRandom.urlsafe_base64(length)
    return random_string
  end

  def self.hours_ago(timestamp)
    diff = Time.now.to_i - timestamp
    # Make sure we check previous hour file in
    # case we are at beginning of new one
    hours_ago = (diff.to_f / 3600.to_f).ceil + 1
    hours_ago
  end

  def self.clean_html(text)
    a = Nokogiri::HTML.parse text
    a.text
  end

  def self.cl_mkdir_p(path)
    begin
      FileUtils.mkdir_p(path)
      FileUtils.chown_R nil, 'syslog', path
      FileUtils.chmod 077, path, verbose: false
    rescue => ex
      puts "Failed to create and set perms on folder #{ex.message}"
    end
  end

end


