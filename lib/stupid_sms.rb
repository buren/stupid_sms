# Stlib
require 'thread'

# Gems
require 'honey_format'

# Local
require 'stupid_sms/version'
require 'stupid_sms/sms_client'
require 'stupid_sms/sms'
require 'stupid_sms/phone'
require 'stupid_sms/process_queue'

module StupidSMS
  MAX_THREADS = 5

  def self.send_in_bulk(csv_string:, template:, country_code: :se, delimiter: ',', dry_run: false, max_threads: MAX_THREADS)
    csv = HoneyFormat::CSV.new(csv_string, delimiter: delimiter)

    sms_queue = Queue.new
    csv.each_row { |person| sms_queue << person }

    summary = ProcessQueue.call(
      sms_queue: sms_queue,
      template: template,
      country_code: country_code,
      dry_run: dry_run,
      max_threads: max_threads
    )

    puts '============================'
    puts "Thread count:  #{max_threads}"
    puts "Dry run:       #{dry_run}"
    puts "Longest sms:   #{summary.fetch(:longest_body)}"
    puts "Recipients:    #{summary.fetch(:recipients_count)}"
    puts "Failed count:  #{summary.fetch(:failed_count)}"
    puts "Sent messages: #{summary.fetch(:successfully_sent_count)}"
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
