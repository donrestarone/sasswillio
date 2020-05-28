
# remove
require 'pry'

module Formatter
  def self.aggregate_sms_prices_obj(twilio_sms_pricing_res)
    local_price_inbound = twilio_sms_pricing_res.inbound_sms_prices.find{|n| n["number_type"] == 'local'}
    local_price_outbound = twilio_sms_pricing_res.outbound_sms_prices.map{|n| n["prices"].find{|i| i["number_type"] == 'local'}}
    return {
      inbound_sms_price_for_local_number: local_price_inbound ? local_price_inbound["current_price"] : 'no local numbers available, so no pricing',
      average_outbound_sms_price_for_local_number: local_price_outbound ? local_price_outbound.map{|n| n["current_price"].to_f}.inject{|sum, el| sum+el} / twilio_sms_pricing_res.outbound_sms_prices.size : 'no local numbers available, so no pricing',
      currency: twilio_sms_pricing_res.price_unit,
    }
  end
end