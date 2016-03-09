class Util
	
	def self.measure_delta
		start_time = Time.now.to_f
		yield
		end_time = Time.now.to_f
		return end_time - start_time
	end

  def self.suid(length=16)
    prefix = rand(10).to_s
    random_string = prefix + ::SecureRandom.urlsafe_base64(length)
    return random_string
  end
end


