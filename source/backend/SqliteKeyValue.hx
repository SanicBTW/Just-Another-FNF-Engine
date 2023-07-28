package backend;

// Add encryption options
// The only difference between the system and html implementations are only the constructor and getters
// Planning on doing a base class that contains operations and that shit, extending it to add different implementations
import flixel.util.FlxDestroyUtil.IFlxDestroyable;
import haxe.crypto.Base64;
import haxe.io.Bytes;
#if sys
import haxe.io.Path;
import sys.FileSystem;
import sys.db.Connection;
import sys.db.ResultSet;
import sys.db.Sqlite;
import sys.io.File;
import sys.thread.Mutex;
import sys.thread.Tls;

/**
 * A string-based key value store using Sqlite as backend.
 * This is expected to be thread safe.
 * @author Ceramic
 */
class SqliteKeyValue implements IFlxDestroyable
{
	private static final APPEND_ENTRIES_LIMIT:Int = 128;

	private var path:String;
	private var table:String;
	private var escapedTable:String;
	private var connections:Array<Connection>;
	private var tlsConnection:Tls<Connection>;

	private var mutex:Mutex;
	private var mutexAcquiredInParent:Bool = false;

	private function getConnection():Connection
	{
		var connection:Connection = tlsConnection.value;
		if (connection == null)
		{
			connection = Sqlite.open(path);
			connections.push(connection);
			tlsConnection.value = connection;
		}
		return connection;
	}

	public function new(path:String, table:String = 'KeyValue')
	{
		mutex = new Mutex();
		mutex.acquire();
		connections = [];
		tlsConnection = new Tls();
		mutex.release();

		this.path = path;
		this.table = table;
		this.escapedTable = escape(table);

		if (!FileSystem.exists(Path.directory(path)))
			FileSystem.createDirectory(Path.directory(path));

		if (!FileSystem.exists(path))
			createDB();
	}

	public function set(key:String, value:String):Bool
	{
		if (value == null)
			return throw("Cannot set a NULL value");

		var escapedKey:String = escape(key);

		var valueBytes:Bytes = Bytes.ofString(value, UTF8);
		var escapedValue:String = "'" + Base64.encode(valueBytes) + "'";

		if (!mutexAcquiredInParent)
			mutex.acquire();

		try
		{
			var connection:Connection = getConnection();
			connection.request('BEGIN TRANSACTION');
			connection.request('INSERT OR REPLACE INTO $escapedTable (key, value) VALUES ($escapedKey, $escapedValue)');
			connection.request('COMMIT');
		}
		catch (exc:Dynamic)
		{
			trace('Failed to set value for key $key: $exc');
			if (!mutexAcquiredInParent)
				mutex.release();
			return false;
		}

		if (!mutexAcquiredInParent)
			mutex.release();

		return true;
	}

	public function remove(key:String):Bool
	{
		var escapedKey:String = escape(key);

		if (!mutexAcquiredInParent)
			mutex.acquire();

		try
		{
			var connection:Connection = getConnection();
			connection.request('DELETE FROM $escapedTable WHERE key = $escapedKey');
		}
		catch (exc:Dynamic)
		{
			trace('Failed to remove value for key $key: $exc');
			if (!mutexAcquiredInParent)
				mutex.release();
			return false;
		}

		if (!mutexAcquiredInParent)
			mutex.release();

		return true;
	}

	public function get(key:String):Null<String>
	{
		var escapedKey:String = escape(key);

		mutex.acquire();

		var value:StringBuf = null;
		var numEntries:Int = 0;

		try
		{
			var connection:Connection = getConnection();
			var result:ResultSet = connection.request('SELECT value FROM $escapedTable WHERE key = $escapedKey ORDER BY id ASC');

			for (entry in result)
			{
				if (value == null)
					value = new StringBuf();

				var rawValue:String = entry.value;
				var rawBytes:Bytes = Base64.decode(rawValue);
				value.add(rawBytes.toString());
				numEntries++;
			}
		}
		catch (exc:Dynamic)
		{
			trace('Failed to get value for key $key: $exc');
			mutex.release();
			return null;
		}

		if (numEntries > APPEND_ENTRIES_LIMIT)
		{
			mutexAcquiredInParent = true;
			set(key, value.toString());
			mutexAcquiredInParent = false;
		}

		mutex.release();
		return value != null ? value.toString() : null;
	}

	public function destroy():Void
	{
		mutex.acquire();
		for (connection in connections)
		{
			connection.close();
		}
		mutex.release();
	}

	// Internal use only

	private static inline function escape(token:String):String
		return "'" + StringTools.replace(token, "'", "''") + "'";

	private function createDB():Void
	{
		mutex.acquire();

		var connection:Connection = getConnection();
		connection.request('BEGIN TRANSACTION');
		connection.request('PRAGMA encoding = "UTF-8"');
		connection.request('
            CREATE TABLE $escapedTable (
                id INTEGER PRIMARY KEY,
                key TEXT NOT NULL,
                value TEXT NOT NULL
            )
        ');
		connection.request('CREATE INDEX key_idx ON $escapedTable(key)');
		connection.request('COMMIT');
		trace("Created DB");

		mutex.release();
	}
}
#elseif html5
import js.Browser;
import js.html.idb.*;
import js.lib.Promise;

/**
 * A string-based key value store using IndexedDB as backend.
 * This is expected to be thread safe.
 * @author Ceramic (SQLite Implemenation), sanco (IndexedDB implementation)
 */
class SqliteKeyValue implements IFlxDestroyable
{
	private var request:OpenDBRequest;
	private var connection:Database;

	private var name:String;
	private var table:String;
	private var version:Int;

	public var onConnect:SqliteKeyValue->Void;

	public function new(name:String, table:String = 'KeyValue', version:Int = 1)
	{
		this.name = name;
		this.table = table;
		this.version = version;

		request = Browser.window.indexedDB.open(name, version);

		request.addEventListener('error', () ->
		{
			throw request.error;
		});

		request.addEventListener('upgradeneeded', (ev) ->
		{
			var db:Database = ev.target.result;
			trace('$name database needs an update');

			if (!db.objectStoreNames.contains(table))
				db.createObjectStore(table);

			trace('finished updating $name');
		});

		request.addEventListener('success', () ->
		{
			connection = request.result;
			trace('connected to $name');
			onConnect(this);
		});
	}

	public function set(key:String, value:String):Bool
	{
		if (connection == null)
			return false;

		var res:Request = connection.transaction(table, READWRITE).objectStore(table).put(Base64.encode(Bytes.ofString(value, UTF8)), key);
		res.addEventListener('error', () ->
		{
			throw res.error;
		});

		return true;
	}

	public function remove(key:String):Bool
	{
		if (connection == null)
			return false;

		var res:Request = connection.transaction(table, READWRITE).objectStore(table).delete(key);
		res.addEventListener('error', () ->
		{
			throw res.error;
		});

		return true;
	}

	public function get(key:String):Promise<String>
	{
		if (connection == null)
			return null;

		var res:Request = connection.transaction(table, READWRITE).objectStore(table).get(key);

		var promise:Promise<String> = new Promise<String>((resolve, reject) ->
		{
			res.addEventListener('success', () ->
			{
				resolve(Base64.decode(res.result).toString());
			});

			res.addEventListener('error', () ->
			{
				reject(res.error);
				throw res.error;
			});
		});

		return promise;
	}

	public function destroy():Void
	{
		connection.close();
	}
}
#end
