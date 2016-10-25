module StupidSMS
  module SMS
    def self.send(client: SMSClient.new, recipient:, body:)
      from_number = StupidSMS.configuration.from_number
      client.send_message(from: from_number, to: recipient, body: body)
      true
    rescue Twilio::REST::RequestError => e # the user has unsubscribed
      puts "[StupidSMS ERROR] Twilio::REST::RequestError to: #{recipient} body: #{body}"
      puts e
      false
    end
  end
end
