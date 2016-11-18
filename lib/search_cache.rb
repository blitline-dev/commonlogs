# -------------------
# Caches search terms with
# skip results.
# -------------------
class SearchCache
  def initialize(tag)
    @tag = tag
    @base_path = Tags.tag_folder(@tag)
    ensure_cache_filepath
  end

  def check_cache_for_files(full_filepaths, text)
    cache_key = Base64.urlsafe_encode64(text)
    files = get_skip_files(cache_key)
    full_filepaths.delete_if do |file_path|
      files.include?(file_path)
    end
    return full_filepaths
  end

  def get_skip_files(cache_key)
    skip_files = []
    skip_files = Marshal.load(File.binread(cache_filepath(cache_key))) if File.exist?(cache_filepath(cache_key))
    return skip_files
  end

  def set_skip_files(full_filepaths, text)
    cache_key = Base64.urlsafe_encode64(text)
    skip_files = get_skip_files(cache_key)
    skip_files += full_filepaths
    skip_files.uniq!
    File.open(cache_filepath(cache_key), 'wb') { |f| f.write(Marshal.dump(skip_files)) }
  end

  def cache_filepath(cache_key)
    @base_path + "/cache/" + cache_key
  end

  def ensure_cache_filepath
    dir_name = @base_path + "/cache/"
    Util.cl_mkdir_p(dir_name) unless File.directory?(dir_name)
  end


end

