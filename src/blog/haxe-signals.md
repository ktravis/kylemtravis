@name = Haxe Signals
@published = 2014-05-16

A common pattern I find myself following in game development is the message-subscription/callback model -- notifying a group of objects that a certain event has happened, at which point they all go about their business responding in the appropriate ways.

This can be really effective, especially for organization, but I rarely seem to fully implement the procedure, instead just hacking something together that works. Realizing that going the full distance wouldn't require much more (and could mean having something more portable to work with) I put together a simple manager for a messaging system:

```haxe
class Signal
{
    static private var signals:Map<String,Array<Dynamic->Bool>> =
        new Map<String,Array<Dynamic->Bool>>();
    static private var oneoff:Map<String,Array<Dynamic->Bool>> =
        new Map<String,Array<Dynamic->Bool>>();

    static public function send(event:String, ?caller:Dynamic = null)
    {
        if (signals.exists(event))
            for (f in signals[event])
                if (!f(caller))
                    signals[event].remove(f);
        if (oneoff.exists(event))
            while (oneoff[event].length > 0)
                oneoff[event].pop()(caller);
    }
    static public function on(event:String, callback:Dynamic->Bool)
    {
        if (signals.exists(event))
            signals[event].push(callback);
        else
            signals[event] = [ callback ];
    }
    static public function first(event:String, callback:Dynamic->Bool)
    {
        if (oneoff.exists(event))
            oneoff[event].push(callback);
        else
            oneoff[event] = [ callback, ];
    }

    static public function clear()
    {
        signals = new Map<String,Array<Dynamic->Bool>>();
        oneoff = new Map<String,Array<Dynamic->Bool>>();
    }
}
```

It seemed intuitive to handle everything statically -- I can't imagine a situation where two signal managers would be necessary, although perhaps there is a better way to set everything up.

In this case I'm storing callback functions in HashMaps that use a string (the signal/message name) as keys. Whenever that signal is sent, the callbacks are evaluated, and if they return false they are removed from the pool. I maintain a separate map for callbacks that should be discarded after the first time a signal is sent, but this could be consolidated by simply wrapping each of those in a closure that always returns `false`.

To subscribe to a signal, say `game_tick`, an object would call `Signal.on('game_tick', function(c) { ... });` where the second argument is the function to execute. The `Signal.first(...)` interface subscribes to only one such event.

Sending a signal is as simple as `Signal.send('game_tick', this)`, where the second argument optionally includes information about the sender.
