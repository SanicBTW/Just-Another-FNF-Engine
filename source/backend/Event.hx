package backend;

using backend.Extensions;

/* old: Custom event shit, based on some custom JS Event thingy I made, cuz signals suck most of the time
	Mix between (old) https://github.com/SanicBTW/sanicbtw/blob/testing/src/scripts/FPSLoop.js#L5 and https://github.com/Sirox228/CustomEvents/blob/main/customevents/Event.hx
	bro you only took 10 minutes to change the comment wtf
 */
@:publicFields
class Event<T>
{
	private var event:String = "DefaultEvent";
	private var listeners:Array<T->Void> = [];

	function new(event:String)
	{
		this.event = event;
	}

	function add(callback:T->Void):Event<T>
	{
		this.listeners.push(callback);
		return this;
	}

	function dispatch(args:T):Event<T>
	{
		for (callback in this.listeners)
		{
			Reflect.callMethod(this, callback, [args]);
		}
		return this;
	}

	function remove(callback:T->Void):Event<T>
	{
		this.listeners.splice(this.listeners.indexOf(callback), 1);
		return this;
	}
}

@:publicFields
class EventGroup<T>
{
	private var eventMap:Map<String, Event<T>> = new Map<String, Event<T>>();

	function new() {}

	function addEvent(eventName:String):Null<Event<T>>
	{
		if (eventMap.exists(eventName))
			return null;

		var event:Event<T> = new Event<T>(eventName);
		eventMap.set(eventName, event);
		return event;
	}

	function addCallbackTo(callback:T->Void, eventName:String):Null<Event<T>>
	{
		var event:Null<Event<T>> = eventMap.get(eventName);
		if (event == null)
			return null;

		return event.add(callback);
	}

	function triggerEvent(eventName:String, args:T):Null<Event<T>>
	{
		var event:Null<Event<T>> = eventMap.get(eventName);
		if (event == null)
			return null;

		return event.dispatch(args);
	}

	function removeEventCallback(callback:T->Void, eventName:String):Null<Event<T>>
	{
		var event:Null<Event<T>> = eventMap.get(eventName);
		if (event == null)
			return null;

		return event.remove(callback);
	}

	function removeEvent(eventName:String)
	{
		var event:Null<Event<T>> = eventMap.get(eventName);
		event = null;
		eventMap.remove(eventName);
	}
}
