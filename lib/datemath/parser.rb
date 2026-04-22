# frozen_string_literal: true

require 'bigdecimal'

module Datemath
  class Parser

    MAX_LENGTH = 50
    MAX_DIGITS = 10
    UNITS = %w[y M w d h m s ms].freeze

    class ParseError < ArgumentError; end

    class << self
      # @return [ActiveSupport::Duration]
      def build_duration(quantity, unit)
        case unit
        when 'y'
          quantity.years
        when 'M'
          quantity.months
        when 'w'
          quantity.weeks
        when 'd'
          quantity.days
        when 'h'
          quantity.hours
        when 'm'
          quantity.minutes
        when 's'
          quantity.seconds
        when 'ms'
          quantity.seconds / 1000.0
        else
          raise ParseError.new "unit must be one of #{UNITS.join(',')}, got #{unit}"
        end
      end

      # Applies end_of_* methods to round up dates
      #
      # @param [DateTime] date_time
      # @param [String] unit
      # @param [Boolean] up
      # @return [DateTime]
      def date_time_round(date_time, unit, up:)
        method = up ? :end_of : :beginning_of

        case unit
        when 'y'
          date_time.public_send(:"#{method}_year")
        when 'M'
          date_time.public_send(:"#{method}_month")
        when 'w'
          date_time.public_send(:"#{method}_week")
        when 'd'
          date_time.public_send(:"#{method}_day")
        when 'h'
          date_time.public_send(:"#{method}_hour")
        when 'm'
          date_time.public_send(:"#{method}_minute")
        when 's'
          if up
            Time.at(date_time.to_i + BigDecimal('0.999999999')).to_datetime
          else
            Time.at(date_time.to_i).to_datetime
          end
        when 'ms'
          with_ms = date_time.to_f.floor(3)
          if up
            Time.at(with_ms + BigDecimal('0.000999999')).to_datetime
          else
            Time.at(BigDecimal(with_ms.to_s)).to_datetime
          end
        else
          raise ParseError.new("unit must be one of #{UNITS.join(',')}, got #{unit}")
        end
      end

      # Evaluates string to integer
      #
      # @param [String] str
      # @return [Boolean]
      def num?(char)
        !!char&.match?(/[0-9]/)
      end
    end

    # Initialize
    #
    def initialize(text = nil)
      @text = text
    end

    # Parses a datemath string to DateTime
    #
    # @param [String] text
    # @param [Boolean] round_up
    # @param [Boolean] raise_error
    # @return [DateTime]
    def parse(round_up: false, raise_error: false)
      return unless @text.is_a? String
      # raise TypeError, "text must be a String, got #{@text.class}" unless @text.is_a?(String)
      raise ParseError.new("datemath string too long (max #{MAX_LENGTH})") if @text.length > MAX_LENGTH

      if @text.start_with?('now')
        time = DateTime.now
        math_string = @text[3..]
      else
        if (index = @text.index('||'))
          parse_string = @text[0...index]
          math_string = @text[(index + 2)..]
        else
          parse_string = @text
        end

        time = begin
          DateTime.iso8601(parse_string)
        rescue Date::Error
          nil
        end
      end

      return time if math_string.nil? || math_string == '' || time.nil?

      begin
        parse_date_math(math_string, time, round_up)
      rescue ParseError => _e
        raise if raise_error
      end
    end

    private

    # Handles math_string to manipulate a given datetime
    #
    # @param [String] math_string example: '+1d'
    # @param [DateTime] time
    # @param [Boolean] round_up
    # @return [DateTime]
    def parse_date_math(math_string, time, round_up)
      date_time = time
      length = math_string.length
      i = 0

      while i < length
        char = math_string[i]
        i += 1

        type = case char
        when '/'
          :round
        when '+'
          :add
        when '-'
          :subs
        else
          raise ParseError.new("invalid operator #{char.inspect} at offset #{i - 1}")
        end

        # Determine the quantity for the current operation (+, -, /)
        quantity = if type == :round
          # Rounding ("/") does NOT allow an explicit number like "/2d"
          if i < length && self.class.num?(math_string[i])
            raise ParseError.new('rounding does not accept an explicit quantity')
          end

          # Rounding always implies quantity = 1 (e.g. "/d" => 1 day)
          1
        elsif self.class.num?(math_string[i]) # If the next character is a digit, we parse a full number (e.g. "+120d")
          num_from = i # mark where the number starts

          # Advance `i` while we keep seeing digits (consume the full number)
          i += 1 while i < length && self.class.num?(math_string[i])

          # Enforce a max # of digits to prevent pathological inputs (e.g. large numbers or DoS-style inputs)
          raise ParseError.new("quantity exceeds max digits (#{MAX_DIGITS})") if (i - num_from) > MAX_DIGITS

          # Convert the substring into an Integer (base 10) e.g. "123" => 123
          Integer(math_string[num_from...i], 10)
        else
          1 # default quantity is 1 (e.g. "+d" => "+1d")
        end

        parsed_unit = parse_unit(math_string, i)
        raise ParseError.new("missing or invalid unit at offset #{i}") unless parsed_unit

        unit, i = parsed_unit

        case type
        when :round
          date_time = self.class.date_time_round(date_time, unit, up: round_up)
        when :add
          date_time += self.class.build_duration(quantity, unit)
        when :subs
          date_time -= self.class.build_duration(quantity, unit)
        end
      end

      date_time
    end

    # Reads a unit token, preferring the 2-char `ms` unit before 1-char units.
    #
    # @param [String] str
    # @param [Integer] index
    # @return [Array<(String, Integer)>, nil]
    def parse_unit(str, index)
      if str[index, 2] == 'ms'
        ['ms', index + 2]
      else
        unit = str[index]
        return unless UNITS.include?(unit)

        [unit, index + 1]
      end
    end

  end
end