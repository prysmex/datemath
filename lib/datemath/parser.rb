module Datemath
  class Parser

    # Initialize
    #
    def initialize
      @units = ['y', 'M', 'w', 'd', 'h', 'm', 's', 'ms']
      @unitsDesc = @units
      @unitsAsc = @unitsDesc.reverse
    end

    # Parses a datemath string to DateTime
    #
    # @param [String] text
    # @param [Boolean] round_up
    # @return [DateTime]
    def parse(text, round_up = false)
      return nil unless text

      time = nil
      math_string = ''
      index = nil
      parse_string = nil
    
      if (text[0, 3] == 'now') 
        time = DateTime.now
        math_string = text['now'.length..text.length]
      else
        index = text.index('||')
        if index.nil?
          parse_string = text
          math_string = '' 
        else
          parse_string = text[0, index]
          math_string = text[(index + 2)..text.length]
        end
        time = DateTime.parse(parse_string) 
      end

      return time if math_string == nil || math_string == ''
      parse_date_math(math_string, time, round_up)
    end

    # Handles math_string to manipulate a given datetime
    #
    # @param [String] math_string
    # @param [DateTime] time
    # @param [Boolean] round_up
    # @return [DateTime]
    def parse_date_math(math_string, time, round_up)
      date_time = time
      len = math_string.length
      i = 0

      while i < len do
        c = math_string[i]
        i = i + 1
        type = nil
        num = nil
        unit = nil

        type = if c == '/' 
          0
        elsif c == '+'
          1
        elsif c == '-' 
          2
        end

        if !is_num?(math_string[i]) 
          num = 1
        elsif math_string.length == 2 
          num = math_string[i]
        else
          # Finds the complete number of the operation
          numFrom = i
          while is_num?(math_string[i]) do
            i = i + 1
            break if (i > 10) 
          end
          
          parsed_number = if numFrom == (i - 1)
            math_string[numFrom]
          else
            math_string[numFrom, i - 1]
          end

          num = Integer(parsed_number, 10)
        end

        if type == 0
          if num != 1
            break
          end
        end

        unit = math_string[i]
        i = i + 1

        # Completes de unit string (like ms)
        j = i
        while j < len do
          unit_char = math_string[i]
          if /[a-z]/i.match?(unit_char)
            unit += unit_char
            i = i + 1
          else 
            break
          end
          j = j + 1
        end

        if @units.index(unit).nil?
          return date_time
        else
          if type == 0
            if (round_up)
              date_time = date_time_round_up(date_time, unit)
            else
              date_time = date_time_round_down(date_time, unit)
            end
          elsif type == 1
            date_time = date_time_operation(date_time, num, unit, "+")
          elsif type == 2
            date_time = date_time_operation(date_time, num, unit, "-")
          end
        end

      end

      date_time
    end

    # Evaluates string to integer
    #
    # @param [String] str
    # @return [Boolean]
    def is_num?(str)
      !!Integer(str)
    rescue ArgumentError, TypeError
      false
    end

    # Applies datetime operations o add or substract datetime
    #
    # @param [DateTime] date_time
    # @param [Integer] num
    # @param [String] unit
    # @param [String] operation
    # @return [DateTime]
    def date_time_operation(date_time, num, unit, operation)
      case unit
      when "y"
        date_time.public_send(operation, num.public_send("years"))
      when "M"
        date_time.public_send(operation, num.public_send("months"))
      when "w"
        date_time.public_send(operation, num.public_send("weeks"))
      when "d"
        date_time.public_send(operation, num.public_send("days"))
      when "h"
        date_time.public_send(operation, num.public_send("hours"))
      when "m"
        date_time.public_send(operation, num.public_send("minutes"))
      when "s"
        date_time.public_send(operation, num.public_send("seconds"))
      end
    end

    # Applies end_of_* methods to round up dates
    #
    # @param [DateTime] date_time
    # @param [String] unit
    # @return [DateTime]
    def date_time_round_up(date_time, unit)
      case unit
      when "y"
        date_time.end_of_year
      when "M"
        date_time.end_of_month
      when "w"
        date_time.end_of_week
      when "d"
        date_time.end_of_day
      when "h"
        date_time.end_of_hour
      when "m"
        date_time.end_of_minute
      when "s"
        # TODO Handle s and ms
      end
    end

    # Applies beginning_of_* methods to round down dates
    #
    # @param [DateTime] date_time
    # @param [String] unit
    # @return [DateTime]
    def date_time_round_down(date_time, unit)
      case unit
      when "y"
        date_time.beginning_of_year
      when "M"
        date_time.beginning_of_month
      when "w"
        date_time.beginning_of_week
      when "d"
        date_time.beginning_of_day
      when "h"
        date_time.beginning_of_hour
      when "m"
        date_time.beginning_of_minute
      when "s"
        # TODO Handle s and ms
      end
    end

  end
end