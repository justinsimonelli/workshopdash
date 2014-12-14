require "YAML"

module WorkshopDash
  # A class to load, manipulate, and store a YAML files properties
  class FileData
    
    # Create a new FileData instance for the file of the given name. A new file will be created if the file doesn't exist
    def initialize(file_name)
      @file_name = file_name
      reload
    end
    
    # Reload the represented file into memory
    def reload
      @data = YAML::load(File.open(@file_name, (File.exists?(@file_name) ? "r+" : "w+")))
      @data ||= {}
    end
    
    # *property_chain*: The dot-delimited string as the path from root to the desired property. 
    # if this is not given, the entire YAML hash object will be returned.
    # *default*: The default value to be returned if the property doesn't exist
    def prop(property_chain = "", default = nil)
      property = @data
      property_chain.split(/\./).each { |p| property = property[p] if property }
      property = default if !property
      property
    end
    
    # *property_chain*: The dot-delimited string as the path to be created from root to the given value. 
    # *value*: The value to be set at the location defined by the given property_chain
    def prop!(property_chain, value)
      set_value(@data, property_chain.split(/\./), value)
      File.open(@file_name, "w") {|f| f.write @data.to_yaml }
      @data
    end
    
    private
    
    def set_value(data, path, value)
      data[path[0]] = (path.size > 1 ? set_value(data[path[0]] || {}, path[1, path.size], value) : value)
      data
    end
    
  end
end

