# Datemath

Elasticsearch's date parser for Ruby

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'datemath'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install datemath

## Usage

Datemath uses Elasticsearch's date parser to handle date expressions. 

Here are a few examples: 

Current date time: 

```ruby
Datemath::Parser.new("now").parse
```

Specific date time: 

```ruby
Datemath::Parser.new("2015-05-05T00:00:00").parse
```

Complex expression: 

```ruby
Datemath::Parser.new("now+1d").parse
```

Multiple operations: 

```ruby
Datemath::Parser.new("now+1d-1m").parse
```

Rounding: 

```ruby
Datemath::Parser.new("now+1d-1m/d").parse
```

Anchoring dates:

```ruby
Datemath::Parser.new("2015-05-05T00:00:00||+1d-1m").parse
```

You can see more cases here: [here](https://www.elastic.co/guide/en/elasticsearch/client/net-api/current/date-math-expressions.html)

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/prysmex/datemath. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Datemath project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/prysmex/datemath/blob/master/CODE_OF_CONDUCT.md).
