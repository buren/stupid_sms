module StupidSMS
  class ProcessQueue
    MAX_SMS_LENGTH = 160.0

    def self.call(**args)
      new(**args).call
    end

    def initialize(sms_queue:, template:, dry_run:, max_threads:)
      @sms_queue = sms_queue
      @template = template
      @dry_run = dry_run
      @max_threads = Integer(max_threads)

      # Stats
      @recipients_count = @sms_queue.length
    end

    def call
      threads = @max_threads.times.map do
        Thread.new do
          # We need one client per Thread since the Twilio client is not thread safe
          client = build_sms_client

          results = { send_count: 0, longest_body: 0, failed_count: 0 }
          until @sms_queue.empty?
            # TODO: Consider capturing all errors and only log them
            sms_result = process_sms(
              client: client,
              person: @sms_queue.pop
            )

            results[:send_count] += sms_result.fetch(:send_count)
            results[:failed_count] += 1 unless sms_result.fetch(:success)

            body_length = sms_result.fetch(:length)
            if body_length > results[:longest_body]
              results[:longest_body] = body_length
            end
          end

          results
        end
      end

      threads.map(&:join) # Wait for each thread
      calculate_summary(threads: threads)
    end

    private

    def process_sms(client:, person:)
      failed_result = { send_count: 0, length: 0, success: false }

      phone = Phone.normalize(person.phone)
      if Phone.invalid?(phone)
        puts "[StupidSMS ERROR] Invalid phone number: #{person.phone}"
        return failed_result
      end

      body = @template % person.to_h

      send_status = if @dry_run
                      true
                    else
                      SMS.send(client: client, recipient: phone, body: body)
                    end

      if send_status
        sms_count = (body.length / MAX_SMS_LENGTH).floor + 1 # Number of SMS sent
        return { send_count: sms_count, length: body.length, success: true }
      end

      failed_result
    end

    def calculate_summary(threads:)
      longest_body = 0
      successfully_sent_count = 0
      failed_count = 0

      threads.map do |thread|
        result = thread.value
        longest_body = result[:longest_body] if result.fetch(:longest_body) > longest_body
        successfully_sent_count += result.fetch(:send_count)
        failed_count += result.fetch(:failed_count)
      end

      {
        longest_body: longest_body,
        successfully_sent_count: successfully_sent_count,
        failed_count: failed_count,
        recipients_count: @recipients_count
      }
    end

    def build_sms_client
      account_sid = StupidSMS.configuration.account_sid
      auth_token = StupidSMS.configuration.auth_token

      SMSClient.new(account_sid: account_sid, auth_token: auth_token)
    end
  end
end
