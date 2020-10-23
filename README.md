# DGD Tools

DGD Tools is a repository of Ruby tools designed to make the DGD interpreter easier to use. DGD started as an interpreter for a dialect of LPC, the C-like language of LPMuds. It has drifted over the years into a powerful general-purpose dynamic language.

DGD Tools requires Ruby. It comes preinstalled on recent Mac computers, or you can install it yourself on Linux. On Windows, if you're not using WSL or similar, you're going to have a less-than-optimal experience.

## DGD Manifest

DGD Manifest is an experimental library system for [DGD](https://github.com/dworkin/LPC). I don't actually know of a second attempt to set up a library system for it. DGD Manifest is inspired loosely by RubyGems and the Ruby [Bundler](https://bundler.io).

DGD Manifest refers to its libraries as Goods. The file dgd.manifest, if it's present in your application's directory, specifies where and how to find its various libraries. By running "dgd-manifest install", you can install those various files into a complete application.

DGD Manifest is a simple initial library system. I'm sure I'll figure more out as I go along, and I'm sure it'll need changes. But you have to start somewhere!

This work has grown out of [SkotOS and ChatTheatre](https://github.com/ChatTheatre) tasks.

## Installation

You would normally install DGDTools directly: `gem install dgd-tools`.

It's possible to add it to a Ruby's application's Gemfile. Ordinarily you wouldn't.

## Usage

If you have a DGD application that uses DGD Manifest, run `dgd-manifest install` to download its dependencies and create a fully-assembled DGD directory for it. You can also `dgd-manifest test` to make sure its dependencies are downloaded and satisfied without building an application directory.

That fully-assembled DGD directory is named ".root". To run your dgd server, type "dgd-manifest server".

## Using DGD Manifest with your DGD Application

Your app will need a dgd.manifest file, which is a lot like NPM's package.json file.

Here's an example:

```
{
    "name": "eOS",
    "version": "1.0.0",
    "description": "A game platform from the folks at ChatTheatre",
    "app_root": "root",
    "goods": [
        "https://raw.githubusercontent.com/noahgibbs/dgd-tools/main/goods/skotos_httpd.goods"
    ],
    "unbundled_goods": [
        {
            "name": "kernellib",
            "git": {
                "url": "https://github.com/dworkin/cloud-server.git",
                "branch": "master"
            },
            "paths": {
                "src/doc/kernel": "doc/kernel",
                "src/include/kernel": "include/kernel",
                "src/kernel": "kernel"
            }
        }
    ]
}
```

DGD Manifest needs a .goods file for each of your dependencies - or it needs the equivalent of that .goods file, in the form of unbundled_goods. That one line in "goods" is basically the same information in unbundled_goods, just stored at a URL that DGD Manifest can download for you.

A Manifest-enabled DGD codebase can provide Goods files directly and you can use them by their URLs. A non-Manifest codebase may require you to create your own .goods files, or use them directly and unbundled in the dgd.manifest file for your app.

## Creating the Goods

To create a new Manifest-usable library, you'll want to create a Goods file for it.

Here's what those look like:

```
{
    "name": "SkotOS HTTPD",
    "git": {
        "url": "https://github.com/ChatTheatre/SkotOS.git"
    },
    "paths": {
        "skoot/usr/HTTP": "usr/HTTP"
    }
}
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/noahgibbs/dgd-tools.

## License

The gem is available as open source under the terms of the AGPL.
