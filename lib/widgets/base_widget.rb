require "mail"
#require "java"
require "sinatra"
require "json"

module WorkshopDash
  # The base class for all widgets
  class BaseWidget
    include WorkshopDash
    
    CONDITION_REGEX = %r{
      ^\s*(\w+)\s*          # Capture variable name
      (<=?|>=?|==?|!=)\s*   # Capture conditional operator
      (?:(-?\d+(?:\.\d+)?)|(true|false)|['"]([^']*)['"])\s*$  # Capture either a numeric, boolean, or string value
    }x
    
    @@actions = {email: EmailAction }
    
    attr_reader :id, :events, :conf_path, :conf, :conditions
    
    # initialize a new widget with the given id
    def initialize(id, &block)
      @id = id
      @events = []
      @conf_path = "widgets.#{@id}"
      @conf = config(@conf_path)
      @conditions = parse_conditions
      self.class.widgets[id] = self
      
      if block_given?
        instance_eval(&block)
      end
    end
    
    # returns a hash containing all of the initialized widget instances by their id
    def self.widgets
      @@widgets ||= {}
    end
    
    
    # schedules a new event to be sent based on the provided scheduler method parameters.
    # the procedure block passed to this method should return a hash containing the data
    # to be sent to the client. The returned hash will also be evaluated against any 
    # configured conditions for this widget and the respective actions will be executed.
    # 
    # *method*: Scheduler method to use. Defaults to :every
    # *duration*: duration string to schedule with. Defaults to the configured time
    # *callable*: callable object to schedule. Defaults to nil
    # *opts*: options to pass to scheduler. Defaults to {first_in: 0}
    # *block*: &block procedure to schedule
    def schedule_event(method = :every, duration = conf['time'], callable = nil, opts = {first_in: 0}, &block)
      event = lambda do |manual|
        begin
          data = block.call(manual)
          data = {} unless data.is_a?(Hash)
          check_condition(data)
          send_event(@id, data)
        rescue => e
          send_event(@id, {error: e.message})
          raise
        end
      end
      @events << event
      SCHEDULER.send(method, duration, callable, opts) do
        event.call(false)
      end
    end
    
    
    def parse_conditions
      conditions = []
      (conf["conditions"] || {}).map do |action, cond|
        if (matches = CONDITION_REGEX.match(cond))
          variable, op, num, bool, str = matches[1..6]
          op = "==" if op == '=' # so many =
          checked_val = (num.to_f if num) || (bool == 'true' if bool) || str
          conditions << {action: action, variable: variable, op: op, checked_val: checked_val}
        else
          puts "The condition (#{cond}) at path '#{@conf_path}.conditions.#{action}' in config.yml is invalid!"
        end
      end
      conditions
    end
    
    def check_condition(data)
      @conditions.each do |condition|
        next unless (value = data[condition[:variable].to_sym])
        next unless (action = @@actions[condition[:action].to_sym])
        action = action.new(condition[:action], self)
        # If the checked_val is a boolean, and the operator contains a < or >, this will fail
        action.execute(value.send(condition[:op].to_sym, condition[:checked_val]), value)
      end
    end
    
    private :parse_conditions, :check_condition
    
  end
end

# this is the sinatra post listener for when a dashboard widget is physically clicked to be updated
post "/update-widget/:id" do
  request.body.rewind
  auth_token = params["auth_token"]
  if !settings.auth_token || settings.auth_token == auth_token
    widget = WorkshopDash::BaseWidget.widgets[params["id"]]
    if widget
      puts "executing"
      widget.events.each { |x| x.call(true) }
      puts "done"
      204 # response without entity body
    else
      status 404
      "Could not find a Widget for the given ID\n"
    end
  else
    status 401
    "Invalid API key\n"
  end
end
