require 'twilio-ruby'
# usage 
# require 'sasswillio'
# @client = Sasswillio.init
# nums = Sasswillio.list_sms_enabled_phone_numbers_for(@client)
# sms_pricing = Sasswillio.get_sms_pricing_for(@client)
# phone_number_pricing = Sasswillio.get_phone_number_pricing_for(@client)
# subaccount = Sasswillio.create_subaccount(@client, '423')
# sms_pricing = Sasswillio.get_sms_pricing_for(@client, 'FR')
# country_nums = Sasswillio.list_sms_enabled_phone_numbers_for_country(@client, {country_code: 'GB'})

module Sasswillio

  def self.get_credentials
    if ENV['TWILIO_ACCOUNT_SID'] && ENV['TWILIO_ACCOUNT_AUTH_TOKEN']
      return {
        sid: ENV['TWILIO_ACCOUNT_SID'],
        token: ENV['TWILIO_ACCOUNT_AUTH_TOKEN']
      }
    else
      return {
        sid: 'AC7fbd312e3dbfc2a44499e7ef59d5b303',
        token: '1df1dbcdac772278cc7091a0584d3858'
      }
    end
  end

  def self.init
    credentials = Sasswillio.get_credentials
    begin
      return Twilio::REST::Client.new credentials[:sid], credentials[:token]
    rescue Twilio::REST::TwilioError => e
      return {
        error: true,
        errors: [e.message],
        context: 'client initialization'
      }
    end
  end

  def self.get_sms_pricing_for(twilio_client, country = 'CA')
    begin
      return Formatter.aggregate_sms_prices_obj(twilio_client.pricing.v1.messaging.countries(country).fetch)
    rescue Twilio::REST::TwilioError => e
      return {
        error: true,
        errors: [e.message],
        context: 'sms pricing for country'
      }
    end
  end

  def self.get_phone_number_pricing_for(twilio_client, country = 'CA')
    begin
      return twilio_client.pricing.v1.phone_numbers.countries(country).fetch
    rescue Twilio::REST::TwilioError => e
      return {
        error: true,
        errors: [e.message],
        context: 'monthly cost for local & toll free numbers'
      }
    end
  end

  def self.provision_sms_number_for_subaccount(twilio_client, sid, options)
    begin
      return Sasswillio.fetch_subaccount(twilio_client, sid).incoming_phone_numbers.create(
        phone_number: options[:phone_number],
        sms_method: 'POST',
        sms_url: options[:sms_path],
        status_callback: options[:sms_status_path],
        status_callback_method: 'POST',
      )
    rescue Twilio::REST::TwilioError => e
      return {
        error: true,
        errors: [e.message],
        context: 'provision sms number for subaccount'
      }
    end
  end

  def self.list_sms_enabled_phone_numbers_for(twilio_client, options = {country_code: 'CA', region: 'ON', contains: '647'})
    begin
      numbers = twilio_client.available_phone_numbers(options[:country_code]).local.list(
        sms_enabled: true,
        in_region: options[:region],
        contains: "#{options[:contains]}*******"
      )
      return numbers.map{|n| {number: n.phone_number, friendly_name: n.friendly_name, capabilities: {**n.capabilities.transform_keys(&:to_sym)}}}
    rescue Twilio::REST::TwilioError => e
      return {
        error: true,
        errors: [e.message],
        context: 'list sms enable phone numbers'
      }
    end
  end

  def self.list_sms_enabled_phone_numbers_for_country(twilio_client, options = {country_code: 'CA'})
    numbers = Hash.new
    begin
      numbers[:local] = twilio_client.available_phone_numbers(options[:country_code]).local.list(
        sms_enabled: true,
      )
      numbers[:mobile] = twilio_client.available_phone_numbers(options[:country_code]).mobile.list(
        sms_enabled: true,
      )

      transformed = Hash.new
      transformed[:local_numbers] = numbers[:local].map{|n| {number: n.phone_number, friendly_name: n.friendly_name, capabilities: {**n.capabilities.transform_keys(&:to_sym)}}}
      transformed[:mobile_numbers] = numbers[:mobile].map{|n| {number: n.phone_number, friendly_name: n.friendly_name, capabilities: {**n.capabilities.transform_keys(&:to_sym)}}}
      return transformed
    rescue Twilio::REST::TwilioError => e
      return {
        error: true,
        errors: [e.message],
        context: 'list sms enable phone numbers for country'
      }
    end
  end

  def self.create_subaccount(twilio_client, options)
    begin
      # save the sid + token and associate it with your Saas user. This will be used to buy phone numbers and send messages on their behalf
      return twilio_client.api.accounts.create(
        friendly_name: options[:reference],
      )
    rescue Twilio::REST::TwilioError => e
      return {
        error: true,
        errors: [e.message],
        context: 'create subaccount'
      }
    end
  end

  def self.fetch_subaccount(twilio_client, sid)
    begin
      return twilio_client.api.accounts(sid).fetch
    rescue Twilio::REST::TwilioError => e
      return {
        error: true,
        errors: [e.message],
        context: 'fetch subaccount'
      }
    end
  end

  def self.suspend_subaccount(twilio_client, sid)
    # sending and recieving messages is disabled when suspended
    begin
      return Sasswillio.fetch_subaccount(twilio_client, sid).update(status: 'suspended')
    rescue Twilio::REST::TwilioError => e
      return {
        error: true,
        errors: [e.message],
        context: 'suspend subaccount'
      }
    end
  end

  def self.close_subaccount(twilio_client, sid)
    # when closed owned numbers are released back to twilio
    begin
      return Sasswillio.fetch_subaccount(twilio_client, sid).update(status: 'closed')
    rescue Twilio::REST::TwilioError => e
      return {
        error: true,
        errors: [e.message],
        context: 'close subaccount'
      }
    end
  end

  def self.activate_subaccount(twilio_client, sid)
    # sending and recieving messages is possible when activated
    begin
      return Sasswillio.fetch_subaccount(twilio_client, sid).update(status: 'active')
    rescue Twilio::REST::TwilioError => e
      return {
        error: true,
        errors: [e.message],
        context: 'activate subaccount'
      }
    end
  end
    
  def self.get_subaccount_usage(subaccount_sid, subaccount_token, options)
    begin
      sub_account_client = Twilio::REST::Client.new subaccount_sid, subaccount_token
      return sub_account_client.usage.records.list(
        category: 'totalprice',
        start_date: options[:start_date],
        end_date: options[:end_date]
      )
    rescue Twilio::REST::TwilioError => e
      return {
        error: true,
        errors: [e.message],
        context: 'subaccount usage query'
      }
    end
  end

  def self.send_text_message(twilio_client, body, to_number, from_number = "+15005550006")
    begin
      return twilio_client.messages.create(
        body: body, 
        to: to_number,
        from: from_number
      )
    rescue Twilio::REST::TwilioError => e
      return {
        error: true,
        errors: [e.message],
        context: 'send message'
      }
    end
  end
end

require 'sasswillio/formatter'