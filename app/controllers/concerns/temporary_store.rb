# frozen_string_literal: true

# BigBlueButton open source conferencing system - http://www.bigbluebutton.org/.

# Copyright (c) 2018 BigBlueButton Inc. and by respective authors (see below).

# This program is free software; you can redistribute it and/or modify it under the
# terms of the GNU Lesser General Public License as published by the Free Software
# Foundation; either version 3.0 of the License, or (at your option) any later
# version.

# BigBlueButton is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
# PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.

# You should have received a copy of the GNU Lesser General Public License along
# with BigBlueButton; if not, see <http://www.gnu.org/licenses/>.

module TemporaryStore
  include ActiveSupport::Concern

  # creates temporary file with prefix, and return path name
  def store_temp_file(prefix, content)
    init_temp_file_storage
    clean_temp_files

    file = Tempfile.new(prefix, temp_file_folder)
    file.write(content)
    # close without unlinking
    file.close(false)
    file
  end

  # creates a persistent file to put in tmp directory with prefix, and return path name
  def store_perm_file(prefix, content)
    init_temp_file_storage
    clean_temp_files

    filepath = temp_file_path(prefix + SecureRandom.hex)
    file = File.open(filepath, 'w')
    file.write(content)

    file.close
    file
  end

  def read_temp_file(file_path, delete: true)
    begin
      file = File.open(file_path, 'r')
    rescue StandardError
      return nil
    end
    contents = file.read
    file.close
    File.delete(file_path) if delete
    contents
  end

  private

  def temp_file_folder
    Rails.root.join('tmp/bbb-lti')
  end

  def temp_file_path(name)
    Rails.root.join("tmp/bbb-lti/#{name}")
  end

  # delete temp files older than a day
  def clean_temp_files
    Dir.foreach(temp_file_folder).each do |filename|
      File.delete(temp_file_path(filename)) if File.file?(temp_file_path(filename)) && File.mtime(temp_file_path(filename)) < 12.hours.ago
    end
  end

  # create temp directory if it doesn't exist
  def init_temp_file_storage
    FileUtils.mkdir_p(temp_file_folder) unless Dir.exist?(temp_file_folder)
  end
end
