module WorkshopDash
  class EmailAction < Action
    
    def execute(active, value)
      if active
        from = config('from')
        recipients = config('recipients')
        msg = format(config("html-body"), id: widget.id, value: value)
        opts = {subject: config('subject')}
        send_email(from, recipients, msg, opts)
      end
    end
    
    def send_email(from, recipients, html_body, opts = {})
      subject = "#{BaseWidget.name} Automated Notice from [#{widget.id}] job" + (opts[:subject] ? " | #{opts[:subject]}" : "")
      
      recipients.each do |recipient|
        mail = Mail.new
        mail.to = recipient
        mail.from = from
        mail.subject = subject
        mail.html_part do
          content_type 'text/html; charset=UTF-8'
          body html_body
        end
        if opts[:attachments].is_a?(Hash)
          opts[:attachments].each { |key, value| mail.add_file(filename: opts[key], content: File.read(value)) }
        end
        
        mail.delivery_method(:sendmail)
        mail.deliver
        puts "sent email to '#{recipient}' from #{widget.id} widget"
      end
    end
    
    private :send_email
    
  end
end