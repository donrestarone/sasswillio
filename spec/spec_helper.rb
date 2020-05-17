require 'twilio_mock'

config.after(:each) do
  TwilioMock::Mocker.new.clean
end