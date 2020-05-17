require 'sasswillio'
require 'pry'
RSpec.describe Sasswillio do
  before(:each) do
    @client = Sasswillio.init
  end

  it 'initializes the twilio client' do
    client = Sasswillio.init
    expect(client).to be_truthy
    expect(client.class.name).to eql 'Twilio::REST::Client'
  end
end