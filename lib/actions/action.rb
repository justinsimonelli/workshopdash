module WorkshopDash
  class Action
    
    attr_reader :action_id, :widget
    
    def initialize(action_id, widget)
      @action_id = action_id
      @widget = widget
      path = "actions.#{action_id}"
      @action_conf = BaseWidget.config(path, {})
      @widget_conf = BaseWidget.config("#{widget.conf_path}.#{path}", {})
    end
    
    def config(property)
      @widget_conf[property] || @action_conf[property]
    end
    
    def execute(active, value); end
    
  end
end