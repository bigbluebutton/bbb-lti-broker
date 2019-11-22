module TemporaryStore

    # creates temporary file with prefix, and return path name
    def store_temp_file(prefix, content)
        init_temp_file_storage
        clean_temp_files

        file = Tempfile.new(prefix, temp_file_folder)
        file.write(content)
        file.close(false) # close without unlinking
        file

        # file_path = temp_file_path(prefix)
        # file = File.open(file_path, "w+") do |f|
        #     f.puts content
        # end
        # file_path
    end

    def read_temp_file(file_path)
        file = File.open(file_path, "r")
        contents = file.read
        file.close
        File.delete(file_path)
        contents
    end

    private

    # def temp_file_path(prefix)
    #     10.times do
    #         file_path = File.join(temp_file_folder, prefix + SecureRandom.hex)
    #         unless File.exists? file_path
    #             return file_path
    #         end
    #     end
    # end

    def temp_file_folder
        Rails.root.join('tmp', 'bbb-lti')
    end

    # delete temp files older than a day
    def clean_temp_files
        Dir.glob(temp_file_folder).each do |filename|
            File.delete(filename) if File.mtime(filename) < 1.days.ago
        end
    end

    # create temp directory if it doesn't exist
    def init_temp_file_storage
        unless Dir.exist? temp_file_folder
            FileUtils.mkdir_p(temp_file_folder)
        end
    end
end