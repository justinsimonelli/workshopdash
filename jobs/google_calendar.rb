require "net/http"
require "icalendar"
require "open-uri"

class Calendar < WorkshopDash::BaseWidget
  
  #calendars = {"swpim" => "https://www.google.com/calendar/ical/2pmas7ibom39c07el5h9i85gv4%40group.calendar.google.com/private-cfe6edb319114c9d84aff712ac50928f/full.ics"}    
  calendars = {}
  calendars.each do |cal_name, cal_uri|
    new("google_calendar_#{cal_name}").schedule_event do
      
      ics = open(cal_uri, :proxy => proxy_uri.to_s) { |f| f.read }
      cal = Icalendar.parse(ics).first
      events = cal.events
      
      # select only current and upcoming events
      now = Time.now.utc
      events = events.select{ |e| e.dtend.to_time.utc > now }
      
      # sort by start time
      events = events.sort{ |a, b| a.dtstart.to_time.utc <=> b.dtstart.to_time.utc }[0..30]

      events = events.map{ |e| {title: e.summary, startDate: e.dtstart, endDate: e.dtend.to_time.to_date}}
      
      {events: events}
    end
  
  end
  
end