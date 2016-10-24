require 'thread'

require 'stupid_sms/version'
require 'stupid_sms/sms_client'

require 'global_phone'
require 'honey_format'

module StupidSMS
  GlobalPhone.db_path = 'global_phone.json'

  MAX_SMS_LENGTH = 160.0
  MAX_THREADS = 5

  def self.send_bulk_message(csv_string:, delimiter: ',', template:, dry_run: false)
    csv = HoneyFormat::CSV.new(csv_string, delimiter: delimiter)

    longest_body = 0
    successfully_sent_count = 0

    sms_queue = Queue.new
    csv.each_row { |person| sms_queue << person }

    summary = process(
      sms_queue: sms_queue,
      template: template,
      dry_run: dry_run,
      max_threads: MAX_THREADS
    )

    puts '============================'
    puts "Dry run:       #{dry_run}"
    puts "Longest sms:   #{summary.fetch(:longest_body)}"
    puts "Recipients:    #{summary.fetch(:recipients_count)}"
    puts "Sent messages: #{summary.fetch(:successfully_sent_count)}"
  end

  def self.process(sms_queue:, template:, dry_run:, max_threads:)
    longest_body = 0
    successfully_sent_count = 0
    recipients_count = sms_queue.length

    threads = max_threads.times.map do
      Thread.new do
        # We need one client per Thread since the Twilio client is not thread safe
        client = SMSClient.new(account_sid: account_sid, auth_token: auth_token)

        thread_results = { send_count: 0, longest_body: 0 }
        until sms_queue.empty?
          result = process_sms(
            client: client,
            person: sms_queue.pop,
            template: template,
            dry_run: dry_run
          )

          thread_results[:send_count] += result.fetch(:send_count)

          body_length = result.fetch(:length)
          if body_length > thread_results[:longest_body]
            thread_results[:longest_body] = body_length
          end
        end
        thread_results
      end
    end

    threads.map(&:join) # Wait for each thread
    threads.map do |thread|
      result = thread.value
      longest_body = result[:longest_body] if result[:longest_body] > longest_body
      successfully_sent_count += result[:send_count]
    end

    {
      longest_body: longest_body,
      successfully_sent_count: successfully_sent_count,
      recipients_count: recipients_count
    }
  end

  def self.process_sms(client:, person:, template:, dry_run:)
    failed_result = { send_count: 0, length: 0, success: false }

    phone = normalize_phone(person.phone)
    if invalid_phone?(phone)
      puts "[StupidSMS ERROR] Couldn't send SMS to phone number: #{person.phone}"
      return failed_result
    end

    body = template % person.to_h

    send_status = if dry_run
                    true
                  else
                    send_message(client: client, recipient: phone, body: body)
                  end

    if send_status
      sms_count = (body.length / MAX_SMS_LENGTH).floor + 1 # Number of SMS sent
      return { send_count: sms_count, length: body.length, success: true }
    end

    failed_result
  end

  def self.send_message(client:, recipient:, body:)
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
