require 'spec_helper'

describe PubSubHub do
  let(:listener)     { 'Object' }
  let(:registration) { [{ listener: listener }] }

  before do
    @registry = described_class.instance.registry
    PubSubHub.register(some_event: registration)
  end

  after { PubSubHub.register(@registry) if @registery }

  context 'with missing a listener' do
    it 'raises an error' do
      expect do
        PubSubHub.register(some_event: [{ listner_typo: listener }])
      end.to raise_error
    end
  end

  context 'an object subscribed for synchronous notification' do
    it 'runs handler synchronously' do
      Object.expects(:handle_some_event)
      PubSubHub.trigger :some_event
    end
  end

  context 'with a namespaced object' do
    module Level1
      module Level2
        class NestedClass
          def self.handle_hello
            'hola'
          end
        end
      end
    end

    it 'works' do
      PubSubHub.register(hello: [{ listener: 'Level1::Level2::NestedClass' }])
      Level1::Level2::NestedClass.expects(:handle_hello)
      PubSubHub.trigger(:hello)
    end
  end

  context 'an object subscribed for asynchronous notification' do
    let(:registration) { [{ listener: listener, async: true }] }

    it 'runs handler via the async dispatcher' do
      PubSubHub.async_dispatcher.expects(:call).with(Object, :handle_some_event, [])
      PubSubHub.trigger :some_event
    end
  end

  context 'a trigger with arguments' do
    let(:args) { [1, 2, 3] }

    it 'runs handler synchronously' do
      Object.expects(:handle_some_event).with(*args)
      PubSubHub.trigger :some_event, *args
    end
  end

  context 'a handler that raises an error' do
    class FlakyObject
      def self.handle_some_event
        raise
      end
    end

    let(:flakey_listener) { 'FlakyObject' }

    let(:registration) do
      [
        { listener: flakey_listener },
        { listener: listener        },
      ]
    end

    it 'does not affect other handlers' do
      Object.expects(:handle_some_event)
      PubSubHub.trigger :some_event
    end
  end

  describe '.async_dispatcher=' do
    let(:args)         { [1, 2, 3] }
    let(:registration) { [{ listener: listener, async: true }] }
    before             { @async_dispatcher = PubSubHub.async_dispatcher }
    after              { PubSubHub.async_dispatcher = @async_dispatcher }

    it 'calls the dispatcher with the listener, handler method and args' do
      dispatcher = mock()
      dispatcher.expects(:call).with(Object, :handle_some_event, args)
      PubSubHub.async_dispatcher = dispatcher
      PubSubHub.trigger :some_event, *args
    end
  end

  describe '.error_handler=' do
    let(:registration) do
      [
        { listener: listener, handler: :exploding_method }
      ]
    end

    before { @error_handler = PubSubHub.error_handler }
    after  { PubSubHub.error_handler = @error_handler }

    it 'calls the error handler with the exception' do
      handler = mock()
      handler.expects(:call).with(instance_of(NoMethodError))
      PubSubHub.error_handler = handler
      PubSubHub.trigger :some_event
    end
  end

  context 'when nothing is registered to that event' do
    it 'does nothing, successfully' do
      expect { PubSubHub.trigger(:some_unregistered_event) }
        .to_not raise_error
    end
  end
end
