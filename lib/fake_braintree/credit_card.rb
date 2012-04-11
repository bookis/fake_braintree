module FakeBraintree
  class CreditCard
    include Helpers

    def initialize(credit_card_hash_from_params, options)
      set_up_credit_card(credit_card_hash_from_params, options)
      set_expiration_month_and_year
    end

    def update
      if credit_card_exists_in_registry?
        update_existing_credit_card
        response_for_updated_card
      else
        response_for_card_not_found
      end
    end

    def create
      if invalid_credit_card?
        response_for_invalid_card
      else
        add_credit_card_to_registry
        response_for_created_card
      end
    end

    private

    def invalid?
      credit_card_is_failure? || invalid_credit_card?
    end

    def credit_card_is_failure?
      FakeBraintree.failure?(credit_card_number)
    end

    def invalid_credit_card?
      credit_card_number &&
        ! FakeBraintree::VALID_CREDIT_CARDS.include?(credit_card_number)
    end

    def add_credit_card_to_registry
      @hash["token"] = '1234'
      FakeBraintree.registry.credit_cards[token] = @hash
    end

    def update_existing_credit_card
      @hash = credit_card_from_registry.merge!(@hash)
    end

    def response_for_updated_card
      gzipped_response(200, @hash.to_xml(:root => 'credit_card'))
    end

    def response_for_created_card
      gzipped_response(200, @hash.to_xml(:root => 'credit_card'))
    end

    def credit_card_exists_in_registry?
      FakeBraintree.registry.credit_cards.key?(token)
    end

    def credit_card_from_registry
      FakeBraintree.registry.credit_cards[token]
    end

    def response_for_card_not_found
      gzipped_response(404, FakeBraintree.failure_response.to_xml(:root => 'api_error_response'))
    end

    def response_for_invalid_card
      gzipped_response(422, FakeBraintree.failure_response(credit_card_number).to_xml(:root => 'api_error_response'))
    end

    def expiration_month
      expiration_date_parts[0]
    end

    def expiration_year
      expiration_date_parts[1]
    end

    def set_up_credit_card(credit_card_hash_from_params, options)
      @hash = {
        "token"       => options[:token],
        "merchant_id" => options[:merchant_id]
      }.merge(credit_card_hash_from_params)
    end

    def set_expiration_month_and_year
      if expiration_month
        @hash["expiration_month"] = expiration_month
      end

      if expiration_year
        @hash["expiration_year"] = expiration_year
      end
    end

    def credit_card_number
      @hash["number"]
    end

    def token
      @hash['token']
    end

    def expiration_date_parts
      if @hash.key?("expiration_date")
        @hash["expiration_date"].split('/')
      else
        []
      end
    end
  end
end
