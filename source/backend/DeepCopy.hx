package backend;

// not cookin no more :speaking_head: :fire:
// should i keep reference of the object?
class DeepCopy
{
	private var defaultFields:Array<String> = [];
	private var _defaultValues:Map<String, Dynamic> = new Map();

	private var modifiedFields:Array<String> = [];
	private var _modifiedValues:Map<String, Dynamic> = new Map();

	private var _exclusions:Array<String> = [];

	public function new(o:Dynamic, exclusions:Array<String>)
	{
		_exclusions = exclusions;

		defaultFields = Reflect.fields(o);
		trace(defaultFields);
		for (field in defaultFields)
		{
			if (exclusions.indexOf(field) > -1)
				continue; // skip

			_defaultValues.set(field, Reflect.getProperty(o, field));
		}
	}

	public function analyzeChanges(o:Dynamic)
	{
		// run again the constructor behaviour but only add modified fields n values
		for (field in defaultFields)
		{
			if (_exclusions.indexOf(field) > -1)
				continue; // skip

			var defValue:Dynamic = _defaultValues.get(field);
			// check again the fields of the object
			var newVal:Dynamic = Reflect.getProperty(o, field);

			if (defValue != newVal)
			{
				trace('Modified $field with $newVal (default $defValue)');
				modifiedFields.push(field);
				_modifiedValues.set(field, newVal);
			}
		}
	}

	public function revertField(o:Dynamic, field:String)
	{
		if (modifiedFields.indexOf(field) > -1) // found in the array
		{
			trace('Reverting $field (${_modifiedValues.get(field)}) to ${_defaultValues.get(field)}');
			Reflect.setProperty(o, field, _defaultValues.get(field));
		}
	}
}
