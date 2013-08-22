# PubSubHub

[![Build Status](https://travis-ci.org/causes/pubsubhub.png)](https://travis-ci.org/causes/pubsubhub)
[![Code Climate](https://codeclimate.com/github/causes/pubsubhub.png)](https://codeclimate.com/github/causes/pubsubhub)

PubSubHub allows you to loosen the coupling between components in a system by
providing a centralized registry of events and listeners that subscribe to those
events.

For example, given a method `#foo`, on class `Bar`, with a slew of side-effects
(communication with multiple classes outside of `Bar`), you effectively have
tightly coupled `Bar` to a number of different classes in the system. Any change
to those other classes on which `Bar` depends may break it. `PubSubHub` provides
a pattern in which `Bar` can be freed of its dependencies: the parts of the
system that care when `#foo` happens can subscribe to an event, and `Bar` need
not even know that those other parts exist.

You can learn more about the motivation behind PubSubHub in our blog post,
"[Managing side-effects with the Pub-Sub
model](http://causes.github.io/blog/2013/08/08/managing-side-effects-with-the-publish-subscribe-model/)".

## Installation

Add this line to your application's `Gemfile`:

    gem 'pubsubhub'

And then execute:

```bash
$ bundle
```

Or install it yourself as:

```bash
$ gem install pubsubhub
```

## Usage

`PubSubHub` provides a mechanism to subscribe to events and notify objects of
events.

To set up event listeners, pass a hash of events and listeners as follows:

```ruby
PubSubHub.register(
  took_action: [
    { listener: Mailer, async: true },
  ],
)
```

To trigger an event, call `PubSubHub.trigger`. All the arguments are
forwarded to the `listener`.

```ruby
class Action
  def take_action(person)
    # ...
    PubSubHub.trigger :took_action, self, person
  end
end

class Mailer
  def self.handle_took_action(action, person)
    # send `action.creator` an email
  end
end
```

By default, exceptions raised during event propagation are handled by printing
them to standard error. You can set a custom handler by passing in a callable
object to `PubSubHub.error_handler=`. We use this at Causes to integrate with
our `Oops` plug-in, without creating a hard dependency on it:

```ruby
PubSubHub.error_handler = ->(exception) { Oops.log(exception) }
```

Likewise, dispatch of `async: true` events is handled by a callable passed in
to `PubSubHub.async_dispatcher=`. The default implementation just calls
`Object#send` (ie. it is not actually asynchronous). At Causes, we've supplied
a custom dispatcher that relies on the async_observer plug-in:

```ruby
PubSubHub.async_dispatcher = ->(listener, handler, args) do
  listener.async_send(handler, *args)
end
```

Note that `PubSubHub` is usable in any Ruby application; we happen to use it in
a Rails application, and make the call to `PubSubHub.register` in a file in the
`config/initializers/` directory.

## Requirements

`PubSubHub` requires Ruby 2.0 or above.

## Credits

`PubSubHub` is built by Causes.

- come work with us: http://www.causes.com/jobs
- read our Engineering blog: http://causes.github.io/
