require 'currencies/currency'
require 'thread'

class ISO4217::Currency
  class ExchangeBank
    EXPIRY = 60 * 60 # hourly

    def self.instance
      @@singleton
    end

    def initialize
      @rates = {}
      @mutex = Mutex.new
    end

    def add_rate(from, to, rate)
      @mutex.synchronize do
        @rates["#{from}_TO_#{to}".upcase] = {:value => rate, :time => Time.now}
      end
    end

    def get_rate(from, to)
      ret = nil
      @mutex.synchronize do
        ret = @rates["#{from}_TO_#{to}".upcase]
      end
      ret[:value] if ret && ret[:time] >= Time.now - EXPIRY
    end

    def same_currency?(currency1, currency2)
      currency1.upcase == currency2.upcase
    end

    def exchange(cents, from_currency, to_currency)
      rate = get_rate(from_currency, to_currency)
      if rate
        (cents * rate).floor
      else
        from_currency = ISO4217::Currency.from_code(from_currency)
        to_currency = ISO4217::Currency.from_code(to_currency)

        if from_currency && to_currency && from_currency.exchange_rate && to_currency.exchange_rate && (from_currency.exchange_currency == to_currency.exchange_currency)
          add_rate(from_currency.code, to_currency.code, from_currency.exchange_rate / to_currency.exchange_rate)
          ((cents * from_currency.exchange_rate) / to_currency.exchange_rate).floor
        else
          raise Money::UnknownRate, "No conversion rate known for '#{from_currency}' -> '#{to_currency}'"
        end
      end
    end

    @@singleton = ExchangeBank.new
  end
end
