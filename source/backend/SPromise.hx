package backend;

typedef PromiseInit<T> = (resolve:(value:T) -> Void, reject:(reason:Dynamic) -> Void) -> Void;

enum PromiseState
{
	PENDING;
	FULFILLED;
	REJECTED;
}

@:publicFields
class SPromise<T> // Sanco Promise
{
	private var successHandlers:Array<T->Void> = [];
	private var errorHandlers:Array<Dynamic->Void> = [];
	private var state:PromiseState = PENDING;
	private var result:T;
	private var error:Dynamic;

	function new(init:PromiseInit<T>):Void
	{
		#if sys
		haxe.Timer.delay(() ->
		{
			init((value) ->
			{
				if (state == PENDING)
				{
					state = FULFILLED;
					result = value;
					for (handler in successHandlers)
						handler(value);
				}
			}, (reason) ->
				{
					if (state == PENDING)
					{
						state = REJECTED;
						error = reason;
						for (handler in errorHandlers)
							handler(reason);
					}
				});
		}, 3);
		#else
		init((value) ->
		{
			if (state == PENDING)
			{
				state = FULFILLED;
				result = value;
				for (handler in successHandlers)
					handler(value);
			}
		}, (reason) ->
			{
				if (state == PENDING)
				{
					state = REJECTED;
					error = reason;
					for (handler in errorHandlers)
						handler(reason);
				}
			});
		#end
	}

	function then(onFulfilled:T->Void):SPromise<T>
	{
		successHandlers.push(onFulfilled);
		return this;
	}

	function catchError(onRejected:Dynamic->Void):SPromise<T>
	{
		errorHandlers.push(onRejected);
		return this;
	}

	function delay(milliseconds:Int):SPromise<T>
	{
		return new SPromise<T>((resolve, reject) ->
		{
			this.then((value) ->
			{
				haxe.Timer.delay(() ->
				{
					resolve(value);
				}, milliseconds);
			}).catchError((reason) ->
			{
				haxe.Timer.delay(() ->
				{
					reject(reason);
				}, milliseconds);
			});
		});
	}

	static function resolve<T>(result:T):SPromise<T>
	{
		return new SPromise<T>((resolve, _) ->
		{
			resolve(result);
		});
	}

	static function reject<T>(reason:Dynamic):SPromise<T>
	{
		return new SPromise<T>((_, reject) ->
		{
			reject(reason);
		});
	}
}
