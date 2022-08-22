# frozen_string_literal: true

class TemporaryStorage
  include TemporaryStore
  def store(prefix, content)
    store_perm_file(prefix, content)
  end

  def read(file, deletion: true)
    read_temp_file(file, deletion)
  end

  def temp_folder
    temp_file_folder
  end
end
