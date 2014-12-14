require "security"

require_relative "file_data"
#require_relative "jdbc_connection"

module WorkshopDash
  
  @config_file = nil
  @data_file = nil
  
  @name = nil
  @version = nil
  @proxy_uri = nil
  @cycle_time = nil
  
  # Returns the configured name, or 'Dashboard' if no name is configured
  def name
    @name ||= config("name", "WorkshopDash")
  end
  
  # Returns the configured version or '0.0.1' if no version is configured
  def version
    @version ||= config("version", "0.0.1")
  end
  
  # Returns the configured proxy-uri, or throws RuntimeException is no proxy-uri is configured
  def proxy_uri
    @proxy_uri ||= URI.parse(config("proxy-uri"))
  end
  
  # Returns the dashboard cycle time, or throws RuntimeException is no cycle time is configured
  def cycle_time
    @cycle_time ||= config("dashboard-cycle")
  end
  
  # Get the data.yml file to be used to save application specific data
  def data_file
    @data_file ||= FileData.new("data.yml")
  end
  
  # Returns the value at the location defined by the property_chain argument in the config.yml file, 
  # If no default is given and no configuration value exists at the given location, then a RuntimeException will be raised.
  def config(property_chain = "", default = nil)
    @config_file ||= FileData.new("config.yml")
    property = @config_file.prop(property_chain, default)
    raise "The configuration value at '#{property_chain}' is missing in config.yml" if !property
    property
  end
  
  # Returns the first password in the default OSX Keychain that matches the given password_name
  # if no password was matched, a RuntimeException will be raised
  def password(password_name)
    pwd = Security::GenericPassword.find(l: password_name)
    pwd = Security::InternetPassword.find(l: password_name) if !pwd
    raise "A password named '#{password_name}' does not exist in the default keychain" if !pwd
    pwd.password
  end

  
  # A hook for when a class includes this module, so we can also extend it so that module methods 
  # are accessible at both class level and instance level as if it was static in java)
  def self.included(base)
    base.extend(self)
  end
  
  
  # Schedule server restart based on the cron time defined in the config.
  # If the ./start.sh script was not used, the server will shutdown and not restart
  SCHEDULER.cron Class.new.extend(self).config("restart-cron") do
    # send SIGINT to this process to shutdown gracefully
    system("kill -INT #{Process.pid}")
  end

    
end
