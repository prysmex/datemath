# frozen_string_literal: true

require 'bigdecimal'

module Datemath
  class Parser

    UNITS = %w[y M w d h m s ms].freeze

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
          ArgumentError.new("unit must be one of #{UNITS.join(',')}, got #{unit}")
        end
      end

      # Evaluates string to integer
      #
      # @param [String] str
      # @return [Boolean]
      def num?(str)
        !!Integer(str)
      rescue ArgumentError, TypeError
        false
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
    # @return [DateTime]
    def parse(round_up: false)
      return nil unless @text

      math_string = ''
      time = index = parse_string = nil

      if @text[0, 3] == 'now'
        time = DateTime.now
        math_string = @text[3..@text.length]
      else
        index = @text.index('||')
        if index.nil?
          parse_string = @text
          math_string = ''
        else
          parse_string = @text[0, index]
          math_string = @text[(index + 2)..@text.length]
        end
        time = begin
          DateTime.parse(parse_string)
        rescue Date::Error
          nil
        end
      end

      return time if math_string.nil? || math_string == '' || time.nil?

      parse_date_math(math_string, time, round_up)
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
        c = math_string[i]
        i += 1

        type = quantity = unit = nil

        type = case c
        when '/'
          :round
        when '+'
          :add
        when '-'
          :subs
        else
          return
        end

        quantity = if !self.class.num?(math_string[i]) # example "+1d-1m/d" assumes ".../1d"
          1
        elsif math_string.length == 2
          math_string[i]
        else
          # Finds the complete number of the operation
          numFrom = i
          while self.class.num?(math_string[i])
            i += 1
            if i > 10
              break # why?
            end
          end

          parsed_number = if numFrom == (i - 1)
            math_string[numFrom]
          else
            math_string[numFrom, i - 1]
          end

          Integer(parsed_number, 10)
        end

        if type == :round && quantity != 1
          return # why?
        end

        unit = math_string[i]
        return unless UNITS.include?(unit)

        i += 1

        # Completes de unit string (like ms)
        j = i
        while j < length
          unit_char = math_string[i]
          break unless /[a-z]/i.match?(unit_char)

          unit += unit_char
          i += 1

          j += 1
        end

        return date_time unless UNITS.include?(unit)

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

  end
end