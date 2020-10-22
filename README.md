# DidGood

DidGood is an experimental library system for [DGD](https://github.com/dworkin/LPC). DGD is an interpreter for a dialect of LPC, the C-like language of LPMuds. I don't actually know of a second attempt to set up a library system for it. DidGood is inspired loosely by RubyGems and the Ruby [Bundler](https://bundler.io).

DidGood refers to its libraries as Goods. The file dgd.didgood, if it's present in your application's directory, specifies where and how to find its various libraries. By running "didgood install", you can install those various files into a complete application.

DidGood is a simple initial library system. I'm sure I'll figure more out as I go along, and I'm sure it'll need changes. But you have to start somewhere!

This work has grown out of [SkotOS and ChatTheatre](https://github.com/ChatTheatre) tasks.

DidGood requires Ruby. It comes preinstalled on recent Mac computers, or you can install it yourself on Linux. On Windows, if you're not using WSL or similar, you're going to have a less-than-optimal experience.

## Installation

You would normally install DidGood directly: `gem install didgood`.

It's possible to add it to a Ruby's application's Gemfile. Ordinarily you wouldn't.

## Usage

If you have a DGD application that uses didgood, run `didgood install` to download its dependencies and create a fully-assembled DGD directory for it.

## Using DidGood with your DGD Application

DidGood needs you to specify a few things about each library you want to use. The easiest way to do that is with a library file (copied locally) or URL for downloading it - you can use a raw GitHub URL for this, for instance.

## Creating the Goods

To create a new DidGood-usable library, you'll want to create a Goods file for it.

## Design Notes on Libraries

The Kernel Library allows changing some config settings, including the name of the "/usr" dir. Consider some other name? Should definitely decide which direction to set "persistent" and stick with it.

Having admin users exist as library-ettes next to libraries seems highly dubious. But to avoid it, there would need to be a whole other permissions system sitting on top of the Kernel Library (like SkotOS, but more so.)



## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/DidGood. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/DidGood/blob/master/CODE_OF_CONDUCT.md).


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the DidGood project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/DidGood/blob/master/CODE_OF_CONDUCT.md).
