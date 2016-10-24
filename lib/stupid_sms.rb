require 'stupid_sms/version'
require 'stupid_sms/sms_client'

require 'global_phone'
require 'honey_format'

module StupidSMS
  GlobalPhone.db_path = 'global_phone.json'

  MAX_SMS_LENGTH = 160.0

  def self.send_bulk_message(csv_string:, delimiter: ',', template:, dry_run: false)
    csv = HoneyFormat::CSV.new(csv_string, delimiter: delimiter)

    longest_body = 0
    successfully_sent_count = 0
    csv.each_row do |person|
      phone = normalize_phone(person.phone)
      if invalid_phone?(phone)
        puts "[StupidSMS ERROR] Couldn't send SMS to phone number: #{person.phone}"
        next
      end

      body = template % person.to_h
      longest_body = body.length if body.length > longest_body

      send_status = if dry_run
                      true
                    else
                      send_message(recipient: phone, body: body)
                    end

      if send_status
        sms_count = (body.length / MAX_SMS_LENGTH).floor + 1 # Number of SMS sent
        successfully_sent_count += sms_count
      end
    end

    puts '============================'
    puts "Dry run:       #{dry_run}"
    puts "Longest sms:   #{longest_body}"
    puts "Recipients:    #{csv.rows.length}"
    puts "Sent messages: #{successfully_sent_count}"
  end

  def self.send_message(recipient:, body:)
    client.send_message(from: from_number, to: recipient, body: body)
    true
  rescue Twilio::REST::RequestError => e # the user has unsubscribed
    puts "[StupidSMS ERROR] Twilio::REST::RequestError to: #{recipient} body: #{body}"
    puts e
    false
  end

  def self.invalid_phone?(phone)
    GlobalPhone.validate(phone, :se) ? false : true
  end

  def self.normalize_phone(phone)
    GlobalPhone.normalize(phone, :se)
  end

  def self.client
    @client ||= SMSClient.new(account_sid: account_sid, auth_token: auth_token)
  end

  def self.from_number=(from_number)
    @from_number = from_number
  end

  def self.auth_token=(auth_token)
    @auth_token = auth_token
  end

  def self.account_sid=(account_sid)
    @account_sid = account_sid
  end

  def self.from_number
    @from_number || ENV.fetch('TWILIO_NUMBER')
  end

  def self.auth_token
    @auth_token || ENV.fetch('TWILIO_AUTH_TOKEN')
  end

  def self.account_sid
    @account_sid || ENV.fetch('TWILIO_ACCOUNT_SID')
  end
end
