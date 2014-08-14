#
=begin
  You need to install following gems before use the sample code
  
  gem install mail
=end

require 'mail'

module MailSender
  @@mail_options = {
        :address              => "smtp.gmail.com",
        :port                 => 465,
        :domain               => 'gmail.com',       # replace with your domain name
        :authentication       => :plain,
        :enable_starttls_auto => true,
        :ssl                  => true
  }

   def MailSender.email_validation email
    begin
      m = Mail::Address.new(email)
      r = m.domain && m.address == email
    rescue => e
      puts e.inspect
      r = false
    end
  end
  
  def MailSender.validate data
    (raise ArgumentError, "Invalid username #{data['username']}") unless self.email_validation(data['username'])
    (raise ArgumentError, "Invalid destination #{data['email_to']}") unless self.email_validation(data['email_to'])
    (raise ArgumentError, "Invalid source #{data['email_from']}") unless self.email_validation(data['email_from'])
    (raise ArgumentError, "Invalid reply " + data['email_reply']) unless data['email_reply'].nil? || data['email_reply'] == "" || self.email_validation(data['email_reply'])
  end
  
  def MailSender.send_mail data
    self.validate data

    @@mail_options[:user_name] = data['username']
    @@mail_options[:password]  = data['password']
    
    Mail.defaults do
      delivery_method :smtp, @@mail_options 
    end

    Mail.deliver do
      header['Return-path'] = "#{data['email_from_name']} <#{data['email_from']}>"
      to        ["#{data['email_to_name']} <#{data['email_to']}>"]
      from      ["#{data['email_from_name']} <#{data['email_from']}>"]
      reply_to( ["#{data['email_reply_name']} <#{data['email_reply']}>"]) unless data['email_reply'].nil? || data['empth_reply'] == ""
      subject   "#{data['email_subject']}"
      body      "#{data['email_body']}"
    end
  end
end

# Note you could retrieve email data from various source including database, JSon, XML...
data = {
  'username'        => 'joohaek@gmail.com', # login account
  'password'        => 'thepassword',       # login password
  'email_from_name' => 'Joohae Kim',        # Display name of sender
  'email_from'      => 'joohaek@gmail.com', # email of sender
  'email_to_name'   => 'Destination',       # Display name of sender
  'email_to'        => 'joohaek@gmail.com', # email of receiver
  'email_subject'   => 'The subject of the email',
  'email_body'      => 'The main contents of the email'
}

MailSender.send_mail data
