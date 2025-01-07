module PolyPatch
  class Change
    attr_reader :address, :patch

    def initialize(address, patch)
      @address = address
      @patch = patch
    end

    def address_int
      address.to_i(16)
    end

    def patch_data
      patch.gsub(/[0-9a-f]{2}/i) { |match| match.to_i(16).chr }
    end
  end

  class PatchFile
    attr_reader :path, :changes

    def initialize(path, verbose = false)
      @path = path
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
              puts "#{change.address}: #{bin_to_hex(read)} -> #{change.patch}" if @verbose
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

      patch = nil
      File.open(path).each do |line|
        line = line.strip
        next if line.empty? || line.start_with?('#')
      
        if line.start_with?('PATCH:')
          patch = line[/:\s?(.*)$/, 1]
        else
          path, pos = line.split(/:\s?/)

          @changes[path] ||= []
          puts "Duplicate patch #{path}:#{pos}" if @changes[path].any? { |change| change.address == pos }
          @changes[path] << Change.new(pos, patch)
        end
      end

      @changes.each do |file, changes|
        @changes[file] = changes.sort_by(&:address)
      end
      @changes = @changes.sort.to_h
    end
  end
end