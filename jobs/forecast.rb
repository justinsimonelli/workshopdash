require "net/http"
require "icalendar"
require "open-uri"

class Forecast < WorkshopDash::BaseWidget

  new("forecast").schedule_event do
      @apiKey = config('forecast.api-key')
      @lat = config('forecast.latitude')
      @long = config('forecast.longitude')
      @units = config('forecast.units')

      uri = "https://api.forecast.io/forecast/#{@apiKey}/#{@lat},#{@long}?units=#{@units}"

      response = open(uri, :proxy => proxy_uri.to_s) { |f| f.read }

      forecast = JSON.parse(response) 
      forecast_current_temp = forecast["currently"]["temperature"].round
      forecast_current_icon = forecast["currently"]["icon"]
      forecast_current_desc = forecast["currently"]["summary"]
      if forecast["minutely"]  # sometimes this is missing from the response.  I don't know why
        forecast_next_desc  = forecast["minutely"]["summary"]
        forecast_next_icon  = forecast["minutely"]["icon"]
      else
        puts "Did not get minutely forecast data again"
        forecast_next_desc  = "No data"
        forecast_next_icon  = ""
      end
      forecast_later_desc   = forecast["hourly"]["summary"]
      forecast_later_icon   = forecast["hourly"]["icon"]

       {current_temp: "#{forecast_current_temp}&deg;", current_icon: "#{forecast_current_icon}", current_desc: "#{forecast_current_desc}", next_icon: "#{forecast_next_icon}", next_desc: "#{forecast_next_desc}", later_icon: "#{forecast_later_icon}", later_desc: "#{forecast_later_desc}"}

  end
end