module Formatter
  def self.aggregate_sms_prices_obj(twilio_sms_pricing_res)
    pricing_hash = Hash.new
    phone_number_types = twilio_sms_pricing_res.inbound_sms_prices.map{|h| h["number_type"]}
    phone_number_types.each do |type|
      transformed_key_for_inbound = type + '_inbound'
      transformed_key_for_outbound = type + '_outbound_average'
      pricing_hash[transformed_key_for_inbound.to_sym] = twilio_sms_pricing_res.inbound_sms_prices.find{|n| n["number_type"] == type}
      numerator = twilio_sms_pricing_res.outbound_sms_prices.map{|n| n["prices"].find{|i| i["number_type"] == type}}.compact.map{|n| n["current_price"].to_f}.inject{|sum, el| sum+el}
      if numerator && numerator > 0
        pricing_hash[transformed_key_for_outbound.to_sym] = numerator / twilio_sms_pricing_res.outbound_sms_prices.size
      else 
        pricing_hash[transformed_key_for_outbound.to_sym] = nil
      end
    end
    
    local_price_inbound = twilio_sms_pricing_res.inbound_sms_prices.find{|n| n["number_type"] == 'local'}
    local_price_outbound = twilio_sms_pricing_res.outbound_sms_prices.map{|n| n["prices"].find{|i| i["number_type"] == 'local'}}.compact
    return {
      inbound_sms_price_for_local_number: local_price_inbound ? local_price_inbound["current_price"] : 'no local numbers available, so no pricing',
      average_outbound_sms_price_for_local_number: local_price_outbound ? local_price_outbound.map{|n| n["current_price"].to_f}.inject{|sum, el| sum+el} / twilio_sms_pricing_res.outbound_sms_prices.size : 'no local numbers available, so no pricing',
      currency: twilio_sms_pricing_res.price_unit,
      complete_pricing_for_country: {
        **pricing_hash
      }
    }
  end
end