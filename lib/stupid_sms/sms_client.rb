require 'twilio-ruby'

module StupidSMS
  class SMSClient
    def initialize(account_sid: StupidSMS.configuration.account_sid, auth_token: StupidSMS.configuration.auth_token)
      @client = Twilio::REST::Client.new(account_sid, auth_token)
    end

    def send_message(from:, to:, body:)
      puts "[StupidSMS] FROM: #{from}, TO: #{to}, BODY: #{body}"

      @client.messages.create(from: from, to: to, body: body)
    end
  end
end
