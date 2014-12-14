module WorkshopDash
  # A class to handle a Graph Widgets points through time
  class GraphWidget < BaseWidget
    
    # Construct a new GraphWidget with the given string 
    def initialize(id, max_time_span = nil, increment = nil)
      super(id)
      @max_time_span = max_time_span || conf['graph-time-span'] * 60
      @increment = increment || conf['time']
      
      @max_points = find_best_max_points(@max_time_span)
      puts "The max graph points for the '#{id}' graph widget has been set to #{@max_points}"
      @points = []
    end
    
    # This finds the lowest max_points within the range of 100 - 250 so that when 
    # the max_seconds value is reached, the size of the points array is the highest
    def find_best_max_points(max_seconds)
      best_max = data_file.prop("max-graph-points.#{@id}-#{max_seconds}") || 0
      
      if best_max == 0
        best_size = 0
        range = 100..250
        max = range.min
        while (max += 1) <= range.max
          value = size = last = 0
          increment = 5
          while (value += 1) <= max_seconds
            if size == 0 || last + increment <= value
              last = value
              if (size += 1) >= max
                size = (size / 2).ceil
                increment *= 2
              end
            end
          end
          best_max, best_size = max, size if size > best_size
        end
        data_file.prop!("max-graph-points.#{@id}-#{max_seconds}", best_max)
      end
      
      best_max
    end
    
    
    def points(time, value)
      if @points.size == 0 || @points[-1][:x] + @increment <= time
        time_span = (@points.size > 0 ? time - @points[0][:x] : 0)
        
        # add the new data point for the current time and y value
        @points << {x: time, y: value}
        
        # remove every other point and double the increment if there are more than max_points
        if @points.size >= @max_points
          @points = @points.reject.with_index{ |x,i| (i+1).even? }
          @increment *= 2
        end
        
        # remove the first point if the max time span has been reached
        @points.shift if time_span >= @max_time_span        
      end
      @points
    end
    
    # Start this graph widget scheduler, and execute the provided procedure during each increment.
    # The provided procedure must return a hash with {:displayedValue => [number]} as one of the hash entries.
    # The displayedValue should be the y-value to be displayed as the point for the current time.
    def start(&block)
      schedule_event(:every, "#{@increment}s", first_in: 0) do |manual|
        now = Time.now.to_f.round
        
        hash = block.call || {}
        value = hash[:displayedValue]
        
        hash.merge!(points: (value && value >= 0 && !manual ? points(now, value) : @points))
        hash
      end
    end
    
    private :find_best_max_points, :points
    
  end
end
