module PolyPatch
  class Change
    attr_reader :address, :patch, :patch_data, :check, :check_data

    def initialize(address, patch, check)
      @address = address
      @patch = patch
      @check = check

      @patch_data = patch.gsub(/[0-9a-f]{2}/i) { |match| match.to_i(16).chr }
      @check_data = check&.gsub(/[0-9a-f]{2}/i) { |match| match.to_i(16).chr }
    end

    def invalid?(data)
      @check_data && data != @check_data
    end

    def address_int
      address.to_i(16)
    end
  end

  class PatchFile
    attr_reader :path, :changes

    def initialize(paths, verbose = false)
      @paths = Array(paths)
      @verbose = verbose
      init_changes
    end

    def apply(basepath)
      changes.each do |filename, changes|
        path = File.join(basepath, filename)
        size = File.size(path)

        puts "Patching #{path}..."
    
        changes.each do |change|
          if size > change.address_int
            read = File.read(path, change.patch_data.length, change.address_int)
            if read != change.patch_data
              if change.invalid?(read)
                puts "#{change.address}: #{bin_to_hex(read)} -> #{change.patch} -- Does not match check: #{change.check}"
              else
                puts "#{change.address}: #{bin_to_hex(read)} -> #{change.patch}" if @verbose
              end

              # TODO: can we open the file once and write this?  stringio?
              File.write(path, change.patch_data, change.address_int)
            else
              puts "#{change.address}: No change -> #{change.patch}" if @verbose
            end
          else
            puts "Cannot patch #{path}, size #{file.size} is smaller than patched end pos #{change.address_int + change.patch_data.length}"
          end
        end
      end
    end

  private

    def bin_to_hex(data)
      data.each_byte.map { |b| b.to_s(16).rjust(2, '0') }.join.upcase
    end

    def init_changes
      @changes = {}

      patch = check = nil
      @paths.each do |path|
        File.open(path).each do |line|
          line = line.strip
          next if line.empty? || line.start_with?('#')
        
          if line.start_with?('PATCH:')
            patch = line[/:\s?(.*)$/, 1]
            check = nil
          elsif line.start_with?('CHECK:')
            check = line[/:\s?(.*)$/, 1]
          else
            path, pos = line.split(/:\s?/)

            @changes[path] ||= []
            puts "Duplicate patch #{path}:#{pos}" if @changes[path].any? { |change| change.address == pos }
            @changes[path] << Change.new(pos, patch, check)
          end
        end
      end

      # @changes.each do |file, changes|
      #   @changes[file] = changes.sort_by(&:address)
      # end
      @changes = @changes.sort.to_h
    end
  end
end