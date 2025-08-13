# Federails::Moderation


![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/manyfold3d/federails-moderation/ci.yml)
[![Maintainability](https://api.codeclimate.com/v1/badges/19eb4dd4705afea275fa/maintainability)](https://codeclimate.com/github/manyfold3d/federails-moderation/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/19eb4dd4705afea275fa/test_coverage)](https://codeclimate.com/github/manyfold3d/federails-moderation/test_coverage)
![Libraries.io dependency status for latest release](https://img.shields.io/librariesio/release/rubygems/federails-moderation)

![GitHub Release](https://img.shields.io/github/v/release/manyfold3d/federails-moderation)
![Gem Downloads (for latest version)](https://img.shields.io/gem/dtv/federails-moderation)
![Dependent repos (via libraries.io)](https://img.shields.io/librariesio/dependent-repos/rubygems/federails-moderation)

A gem that provides moderation capabilities for [Federails](https://gitlab.com/experimentslabs/federails). It adds the following features:

* Handle incoming `Flag` activities, normally used for reporting content to moderators
* Block federation with particular servers

## Requirements

* [Federails](https://gitlab.com/experimentslabs/federails) >= 0.4
* Ruby >= 3.0

## Installation
Add the gem to your Rails application:

```bash
> bundle add "federails-moderation"
```

Then install the database migrations:

```bash
> bin/rails federails_moderation:install:migrations
> bin/rails db:migrate
```

## Usage

### Reports

When your application receives a `Flag` activitypub message, it will create a `Federails::Moderation::Report` record with the details.

```ruby
# Find all unresolved reports
reports = Federails::Moderation::Report.where(resolution: nil)
r = reports.first

# Reports can have a comment that was sent with them:
puts r.content
# "This message is spam"

# It will be associated with the actor that sent it:
puts r.actor.at_address
# "@floppy@mastodon.me.uk"

# Deal with the report in your app, then either:
r.resolve!
# or, you can ignore it
r.ignore!

```

You can receive a callback in your application when a new report is received, by providing a proc which will be called:

```
Federails::Moderation.configure do |conf|
  conf.after_report_created = ->(report) { MyApp::MyReportHandler.call(report) }
end
```

### Domain Blocks

You can block domains that are abusive like so:

```
Federails::Moderation::DomainBlock.create(domain: "spammer.com")
```

Once the block is created, incoming messages from that domain, or from any actor on that domain, will be ignored. Also, outgoing messages to that domain will be dropped before being delivered.

Actors from the blocked domain aren't currently auto-removed; this may be added in the future, but for now that's left up to your application.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/manyfold3d/federails-moderation. This project is intended to be a safe, welcoming space for collaboration; everyone interacting in the project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/manyfold3d/federails-moderation/blob/master/CODE_OF_CONDUCT.md).

## Support & Community

For help, join the main [Federails matrix chat room](https://matrix.to/#/#federails:matrix.org).

## Acknowledgements

This gem builds on top of [Federails](https://gitlab.com/experimentslabs/federails), by [Manuel Tancoigne](https://gitlab.com/mtancoigne).

This gem was created as part of [Manyfold](https://manyfold.app), with funding from [NGI0 Entrust](https://nlnet.nl/entrust), a fund established by [NLnet](https://nlnet.nl) with financial support from the European Commission's [Next Generation Internet](https://ngi.eu) program.

[<img src="https://nlnet.nl/logo/banner.png" alt="NLnet foundation logo" width="20%" />](https://nlnet.nl)
[<img src="https://nlnet.nl/image/logos/NGI0_tag.svg" alt="NGI Zero Logo" width="20%" />](https://nlnet.nl/entrust)
