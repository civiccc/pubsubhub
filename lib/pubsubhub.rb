require 'singleton'

# The `PubSubHub` provides a mechanism to subscribe to events and notify
# objects of events.
#
# To subscribe to an event, add a hash to
# {file:config/initializers/pub_sub_hub.rb}. The listener must implement
# `handle_#{event_name}`.
#
#     # {file:config/initializers/pub_sub_hub.rb}
#
#     PubSubHub.register(
#       took_action: [
#         { listener: Mailer, async: true },
#       ],
#     )
#
# To trigger an event, call `PubSubHub.trigger`. All the arguments are
# forwarded to the `listener`.
#
#     class Action
#       def take_action(person)
#         # ...
#         PubSubHub.trigger :took_action, self, person
#       end
#     end
#
#     class Mailer
#       def self.handle_took_action(action, person)
#         # send `action.creator` an email
#       end
#     end
#
# By default, exceptions raised during event propagation are handled by printing
# them to standard error. You can set a custom handler by passing in a callable
# object to `PubSubHub.error_handler=`. We use this at Causes to integrate with
# our `Oops` plug-in, without creating a hard dependency on it:
#
#     PubSubHub.error_handler = ->(exception) { Oops.log(exception) }
#
# Likewise, dispatch of `async: true` events is handled by a callable passed in
# to `PubSubHub.async_dispatcher=`. The default implementation just calls
# `Object#send` (ie. it is not actually asynchronous). At Causes, we've supplied
# a custom dispatcher that relies on the async_observer plug-in:
#
#     PubSubHub.async_dispatcher = ->(listener, handler, args) do
#       listener.async_send(handler, *args)
#     end
#
class PubSubHub
  include Singleton

  VERSION = '0.0.1'

  class << self
    # Convenience methods, delegated to the singleton instance. We use
    # `define_method` rather than `delegate` to avoid a dependency on Rails.
    %i[
      async_dispatcher
      async_dispatcher=
      error_handler
      error_handler=
      register
      trigger
    ].each do |method|
      define_method(method) do |*args|
        instance.send(method, *args)
      end
    end
  end

  attr_accessor :async_dispatcher, :error_handler
  attr_reader :registry

  def initialize
    @async_dispatcher = ->(listener, handler, args) do
      listener.send(handler, *args)
    end

    @error_handler = ->(exception) { STDERR.puts exception }
  end

  def register(registry)
    @registry = validate_registry!(registry)
  end

  # Notifies listeners of a event.
  #
  # Arguments are forwarded to the handlers. If the listener registered with
  # `async: true`, `trigger` calls the handler using an asynchronous dispatcher.
  #
  # The default dispatcher just forwards the message directly. For an example of
  # a dispatcher that is actually asynchronous, see
  # {file:config/initializers/pub_sub_hub.rb}, which sets up:
  #
  #   PubSubHub.async_dispatcher = ->(listener, handler, args) do
  #     listener.async_send(handler, *args)
  #   end
  #
  def trigger(event_name, *args)
    @registry[event_name.to_sym].each do |registration|
      begin
        listener = registration[:listener]
        async    = registration[:async]
        handler  = :"handle_#{event_name}"

        if async
          @async_dispatcher.call(listener, handler, args)
        else
          listener.send(handler, *args)
        end
      rescue => e
        @error_handler.call(e)
      end
    end
  end

private

  def validate_registry!(registry)
    registry.each do |event_name, registrations|
      registrations.any? do |registration|
        raise ArgumentError if registration[:listener].blank?
      end
    end
  end
end
