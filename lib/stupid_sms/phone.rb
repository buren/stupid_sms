require 'global_phone'

module StupidSMS
  module Phone
    GlobalPhone.db_path = 'global_phone.json'

    def self.invalid?(phone, country_code: StupidSMS.configuration.country_code)
      GlobalPhone.validate(phone, country_code) ? false : true
    end

    def self.normalize(phone, country_code: StupidSMS.configuration.country_code)
      GlobalPhone.normalize(phone, country_code)
    end
  end
end
