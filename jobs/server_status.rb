require "net/http"
require "uri"

# Check whether a server is responding
# you can set a server to check via http request or ping
#
# server options:
# name: how it will show up on the dashboard
# url: either a website url or an IP address (do not include https:// when usnig ping method)
# method: either 'http' or 'ping'
# if the server you're checking redirects (from http to https for example) the check will
# return false
class ServerStatus < WorkshopDash::BaseWidget
  
  servers = [{name: "v-corp-stbo1-devint", url: "v-corp-stbo1-devint.sherwin.com", method: "ping"},
      {name: "v-corp-stbo2-devint", url: "v-corp-stbo2-devint.sherwin.com", method: "ping"},
      {name: "v-corp-stbo1-labint", url: "v-corp-stbo1-labint.sherwin.com", method: "ping"}]
  
  new("server_status").schedule_event do
    
    statuses = Array.new
    
    # check status for each server
    servers.each do |server|
      if server[:method] == "http"
        uri = URI.parse(server[:url])
        http = Net::HTTP::Proxy(proxy_uri.host, proxy_uri.port).new(uri.host, uri.port)
        if uri.scheme == "https"
          http.use_ssl=true
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end
        request = Net::HTTP::Get.new(uri.request_uri)
        response = http.request(request)
        if response.code == "200"
          result = 1
         else
          result = 0
         end
      elsif server[:method] == "ping"
        ping_count = 10
        result = `ping -q -c #{ping_count} #{server[:url]}`
        if ($?.exitstatus == 0)
          result = 1
        else
          result = 0
        end
      end
      
      if result == 1
        arrow = "icon-ok-sign"
        color = "green"
      else
        arrow = "icon-warning-sign"
        color = "red"
      end
      
      statuses.push({label: server[:name], value: result, arrow: arrow, color: color})
    end
    
    {items: statuses}
  end
  
end