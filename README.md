# StupidSMS

Send bulk SMS using Twilio.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'stupid_sms'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install stupid_sms

## Usage

__Configuration__

```ruby
StupidSMS.from_number = '...' # or set env var TWILIO_ACCOUNT_SID
StupidSMS.auth_token  = '...' # or set env var TWILIO_AUTH_TOKEN
StupidSMS.account_sid = '...' # or set env var TWILIO_NUMBER
```

__Send one SMS__:

```ruby
StupidSMS.send_message(recipient: recipient, body: body)
```

__Send SMS in bulk__:

To send SMS in bulk you construct a special CSV file. The only required column is `phone`.
You include a template string that can include dynamic content, i.e 'Hi %{first_name}'. If you
do include such content in the template we'll look for a column in the CSV-file with the
name `first_name`.

:warning: You need to escape '%' chars with '%%' otherwise `'%': malformed format string - %! (ArgumentError)` will be raised.

`file.csv`:

```csv
phone,first_name
+46735000000,Jacob
```

```ruby
csv = File.read('file.csv')
template = 'Hi %{first_name}!'
StupidSMS.send_in_bulk(csv_string: csv, template: template)
```

```bash
stupid_sms --csv testfile.csv --delimiter=, --template template.txt --dry-run=true
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/buren/stupid_sms.

## License

[MIT License](LICENSE.txt)
