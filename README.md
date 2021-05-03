# DGD Tools

DGD Tools is a repository of Ruby tools designed to make the DGD interpreter easier to use. DGD started as an interpreter for a dialect of LPC, the C-like language of LPMuds. It has drifted over the years into a powerful general-purpose dynamic language.

DGD Tools requires Ruby. It comes preinstalled on recent Mac computers, or you can install it yourself on Linux. On Windows, if you're not using WSL or similar, you're going to have a less-than-optimal experience.

## DGD Manifest

DGD Manifest is an experimental library system for [DGD](https://github.com/dworkin/LPC). I don't actually know of a second attempt to set up a library system for it. DGD Manifest is inspired loosely by RubyGems and the Ruby [Bundler](https://bundler.io).

DGD Manifest refers to its libraries as Goods. The file dgd.manifest, if it's present in your application's directory, specifies where and how to find its various libraries. By running "dgd-manifest install", you can install those various files into a complete application.

DGD Manifest is a simple initial library system. I'm sure I'll figure more out as I go along, and I'm sure it'll need changes. But you have to start somewhere!

This work has grown out of [SkotOS and ChatTheatre](https://github.com/ChatTheatre) tasks.

You can find example DGD manifest files under the "test" directory and also in [various](https://github.com/noahgibbs/prototype_vRWOT) [SkotOS-based games](https://github.com/ChatTheatre/gables_game) that use the DGD Manifest system.

You can find example "goods" (library) files under the "goods" subdirectory of this repo.

## WOE Objects and skotos-xml-diff

SkotOS-based games use an XML format for in-game objects ("/base/obj/thing"), which is [documented in SkotOS-Doc](https://ChatTheatre.github.io/SkotOS-Doc). The skotos-xml-diff utility will diff between Things or directories of Things.

See SkotOS-Doc for more detail about how this can be used with a SkotOS game.

Run "skotos-xml-diff --help" for a list of options. You can tell it to ignore whitespace, to diff only the Merry (script) contents of the objects, and to ignore certain XML node types.

## Installation

You would normally install DGDTools directly: `gem install dgd-tools`.

If you have a Ruby Gemfile or gems.rb that uses it, you can "bundle install" as normal.

## Usage

If you have a DGD application that uses DGD Manifest, run `dgd-manifest install` to download its dependencies and create a clean, fully-assembled DGD directory for it. You can also `dgd-manifest test` to make sure its dependencies are downloaded and satisfied without building an application directory. After the initial install, "dgd-manifest update" will avoid deleting any files you may have added.

NOTE: "dgd-manifest install" will delete any extra files you may have created in the DGD root. "dgd-manifest update" will not. Neither of these is always the right answer.

That fully-assembled DGD directory is named ".root". To run your dgd server, type "dgd-manifest server".

## Creating a New DGD Manifest App

You can type "dgd-manifest new my_app_name" to create a new application using the appropriate DGD manifest structure. This is an easy way to set up an appropriate .gitignore file and similar.

You can, of course, do the same without the command if you like.

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

Fields in the Goods file are the same as fields in unbundled_goods.

## Implementation Limits

Right now it's not possible to use the same repo multiple times with different branches. So for instance, you can't use one branch of ChatTheatre/SkotOS for your main library while using a different branch of it for some other library. For this reason, it's recommended that you extract smaller libraries into their own repositories rather than keeping multiple libraries in the same repo.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/noahgibbs/dgd-tools.

## License

The gem is available as open source under the terms of the AGPL.
