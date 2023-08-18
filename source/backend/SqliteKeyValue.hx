package backend;

import flixel.util.FlxDestroyUtil.IFlxDestroyable;
import haxe.Serializer;
import haxe.Unserializer;
import lime.app.Promise;
#if sys
import backend.io.Path;
import sys.FileSystem;
import sys.db.Connection;
import sys.db.ResultSet;
import sys.db.Sqlite;
import sys.thread.Mutex;
import sys.thread.Tls;

/**
 * A string-based key value store using Sqlite as backend.
 * This is expected to be thread safe.
 * @author Ceramic
 */
class SqliteKeyValue implements IFlxDestroyable extends Promise<SqliteKeyValue>
{
	private static final APPEND_ENTRIES_LIMIT:Int = 128;

	private var path:String;
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

	public function new(params:DBInitParams)
	{
		super();

		mutex = new Mutex();
		mutex.acquire();
		connections = [];
		tlsConnection = new Tls();
		mutex.release();

		this.path = params.path;
		if (!FileSystem.exists(Path.directory(params.path)))
			FileSystem.createDirectory(Path.directory(params.path));

		for (table in params.tables)
		{
			this.createTable(table);
		}

		this.complete(this);
	}

	public function set(table:String = 'KeyValue', key:String, value:Any):Bool
	{
		if (value == null)
			return remove(table, key);

		var escapedTable:String = escape(table);
		var escapedKey:String = escape(key);
		var escapedValue:String = "'" + Serializer.run(value) + "'";

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
			trace('Failed to set value in $table for key $key: $exc');
			if (!mutexAcquiredInParent)
				mutex.release();
			return false;
		}

		if (!mutexAcquiredInParent)
			mutex.release();

		return true;
	}

	public function remove(table:String = 'KeyValue', key:String):Bool
	{
		var escapedTable:String = escape(table);
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
			trace('Failed to remove value in $table for key $key: $exc');
			if (!mutexAcquiredInParent)
				mutex.release();
			return false;
		}

		if (!mutexAcquiredInParent)
			mutex.release();

		return true;
	}

	// TODO: Make promise
	public function get(table:String = 'KeyValue', key:String):Null<Any>
	{
		var escapedTable:String = escape(table);
		var escapedKey:String = escape(key);

		mutex.acquire();

		var res:Null<Any> = null;
		var numEntries:Int = 0;

		try
		{
			var connection:Connection = getConnection();
			var result:ResultSet = connection.request('SELECT value FROM $escapedTable WHERE key = $escapedKey ORDER BY id ASC');

			for (entry in result)
			{
				res = Unserializer.run(entry.value);
				numEntries++;
			}
		}
		catch (exc:Dynamic)
		{
			trace('Failed to get value in $table for key $key: $exc');
			mutex.release();
			return null;
		}

		if (numEntries > APPEND_ENTRIES_LIMIT)
		{
			mutexAcquiredInParent = true;
			set(table, key, res);
			mutexAcquiredInParent = false;
		}

		mutex.release();
		return res;
	}

	@:noCompletion
	private function createTable(table:String = 'KeyValue'):Bool
	{
		var escapedTable:String = escape(table);
		mutex.acquire();

		try
		{
			var connection:Connection = getConnection();
			connection.request('BEGIN TRANSACTION');
			connection.request('PRAGMA encoding = "UTF-8"');
			connection.request('
				CREATE TABLE IF NOT EXISTS $escapedTable (
					id INTEGER PRIMARY KEY,
					key TEXT NOT NULL,
					value TEXT NOT NULL
				)
			');

			if (!FileSystem.exists(path))
				connection.request('CREATE INDEX key_idx ON $escapedTable(key)');

			connection.request('COMMIT');
			trace('Created $table at ${Path.withoutDirectory(path)}');
		}
		catch (exc:Dynamic)
		{
			trace('Failed to create $table at $path: $exc');
			mutex.release();
			return false;
		}

		mutex.release();
		return true;
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
}
#elseif html5
import haxe.exceptions.NotImplementedException;
import js.Browser;
import js.html.idb.*;
import js.lib.Promise;

/**
 * A string-based key value store using IndexedDB as backend.
 * This is expected to be thread safe.
 * @author Ceramic (SQLite Implemenation), sanco (IndexedDB implementation)
 */
class SqliteKeyValue implements IFlxDestroyable extends Promise<SqliteKeyValue>
{
	private var request:OpenDBRequest;
	private var connection:Database;

	private var name:String;
	private var version:Int;

	public function new(params:DBInitParams)
	{
		super();

		this.name = params.path;
		this.version = params.version;

		request = Browser.window.indexedDB.open(name, version);

		request.addEventListener('error', () ->
		{
			throw request.error;
		});

		request.addEventListener('upgradeneeded', (ev) ->
		{
			var db:Database = ev.target.result;

			for (table in params.tables)
			{
				if (!db.objectStoreNames.contains(table))
					db.createObjectStore(table);
			}
		});

		request.addEventListener('success', () ->
		{
			connection = request.result;
			this.complete(this);
		});
	}

	public function set(table:String = 'KeyValue', key:String, value:Any):Bool
	{
		if (connection == null)
			return false;

		if (value == null)
			return remove(table, key);

		var res:Request = connection.transaction(table, READWRITE).objectStore(table).put(Serializer.run(value), key);
		res.addEventListener('error', () ->
		{
			throw res.error;
		});

		return true;
	}

	public function remove(table:String = 'KeyValue', key:String):Bool
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

	public function get(table:String = 'KeyValue', key:String):Promise<Any>
	{
		if (connection == null)
			return null;

		var res:Request = connection.transaction(table, READWRITE).objectStore(table).get(key);

		var promise:Promise<String> = new Promise<String>((resolve, reject) ->
		{
			res.addEventListener('success', () ->
			{
				if (res.result != null)
					resolve(Unserializer.run(res.result));
				else
					resolve(null);
			});

			res.addEventListener('error', () ->
			{
				reject(res.error);
				throw res.error;
			});
		});

		return promise;
	}

	public function createTable(table:String = 'KeyValue'):Bool
	{
		throw new NotImplementedException();
	}

	public function destroy():Void
	{
		connection.close();
	}
}
#end

typedef DBInitParams =
{
	var path:String;
	var tables:Array<String>;
	var ?version:Int;
}
