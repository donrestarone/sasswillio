# sasswillio
a simple ruby gem that wraps around the twilio API allowing you to build an SMS enabled SaaS product more erganomically.


##### Table of Contents  
[Installation](#install)

[SaaS model & assumptions](#sassmodel)

[initializing the twilio client](#init)

[creating subaccounts](#subaccounts)

[buying phone numbers for subaccounts](#phonenums)

[view usage](#usage)

[subaccount control and preventing abuse](#control)
  
<a name="install"/>

## Installation

In gemfile (ex; rack applications like Rails, Sinatra) 

```ruby
gem 'sasswillio', '~> 1.0'
```
Install globally

```bash
gem install sasswillio
```
Then make sure that your credentials are saved in your ENV (bashrc for Linux, bash_profile for Mac) as:

```bash
TWILIO_ACCOUNT_SID="yourtwiliosid"
TWILIO_ACCOUNT_AUTH_TOKEN="yourtwilioauthtoken"
```

<a name="sassmodel"/>

## SaaS model & assumptions

Twilio allows you to create a Saas product on top of their API in many ways. This gem uses subaccounts so you as the developer can programatically setup a subaccount for each of your subscribers. A subaccount can have many phone numbers associated with it and allow for permissions to be set by the root account (which is controlled by your SaaS product). If subscribers fail to pay or violate your terms their subaccounts can be either suspended (blocked from sending or recieving SMS messages) or simply closed. When subaccounts are closed, the associated phone numbers are automatically released to twilio.

<a name="init"/>

## initializing the twilio client

Create an instance of the client

```ruby
@client = Sasswillio.init
```

<a name="subaccounts"/>

## creating subaccounts

Create a subaccount for your subscriber. Don't forget to grab the return value and associate the sid and token with your subscriber. You will need to use the subaccount sid and auth token when performing actions on behalf of the subscriber. In this example we are passing the primary key of the subscriber to Twilio so it will set that as the 'friendly name' of the subscriber.

```ruby
subaccount = Sasswillio.create_subaccount(@client, {reference: 434})
sid = subaccount.sid
token = subaccount.auth_token
```

<a name="phonenums"/>

## buying phone numbers for subaccounts

In this example, we are listing phone numbers for Canada, in the province of Ontario and numbers that start with 289. 

```ruby
numbers = Sasswillio.list_sms_enabled_phone_numbers_for(
  @client, 
  {
    country_code: 'CA', 
    region: 'ON', 
    contains: '289'
  }
)
p numbers
[{:number=>"+16473711080", :capabilities=>{:voice=>true, :SMS=>true, :MMS=>true, :fax=>true}}, {:number=>"+16473711150", :capabilities=>{:voice=>true, :SMS=>true, :MMS=>true, :fax=>true}}, {:number=>"+16473711025", :capabilities=>{:voice=>true, :SMS=>true, :MMS=>true, :fax=>true}}]
```

The 'rental cost' for phone numbers can be queried by specifying the country: 

```ruby
pricing = Sasswillio.get_phone_number_pricing_for(@client, 'CA')
p pricing 
<Twilio.Pricing.V1.CountryInstance country: Canada iso_country: CA phone_number_prices: [{"number_type"=>"local", "base_price"=>"1.00", "current_price"=>"1.00"}, {"number_type"=>"toll free", "base_price"=>"2.00", "current_price"=>"2.00"}] price_unit: USD url: https://pricing.twilio.com/v1/PhoneNumbers/Countries/CA>
```

To buy a specific phone number for the subscriber; we pass the root account, the subaccount sid and the desired phone number along with the callback URL for when that number recieves a message. You can also specify an sms_status_path which twilio will use to send webhooks regarding the message status (sent, delivered etc).

```ruby
phone_number = Sasswillio.provision_sms_number_for_subaccount(
  @client, 
  subaccount_sid, 
  {
    phone_number: '+1xxxxxxxxxx', 
    sms_path: 'https://foo.bar', 
    sms_status_path: 'https://foo.baz'
  }
)
```

<a name="usage"/>

## view usage

specify the subaccount sid and its token and a date range.

```ruby
usage = Sasswillio.get_subaccount_usage(
  subaccount_sid, 
  subaccount_token, 
  {
    start_date: (Time.now - 1.day).to_date, 
    end_date: (Time.now).to_date
  }
)
usage.each{|u| p u.price}
```

<a name="control"/>

## subaccount control and preventing abuse

To control subaccounts and prevent abuse, you will need to write logic in your application. This logic will invoke 2 methods that suspend and/or close subscriber subaccounts. Here we pass the root account and the sid of the subaccount we need to suspend.

```ruby
suspend = Sasswillio.suspend_subaccount(@client, subaccount_sid) 
```

to close a subaccount and release its numbers to twilio: 

```ruby
close = Sasswillio.close_subaccount(@client, subaccount_sid) 
```

