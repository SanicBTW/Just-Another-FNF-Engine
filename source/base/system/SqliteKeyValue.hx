package base.system;

#if sys
import flixel.util.FlxDestroyUtil.IFlxDestroyable;
import haxe.Exception;
import haxe.crypto.Base64;
import haxe.io.Bytes;
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

		escapedTable = escape(table);

		if (!FileSystem.exists(Path.directory(path)))
			FileSystem.createDirectory(Path.directory(path));

		if (!FileSystem.exists(path))
			createDB();
	}

	public function set(key:String, value:String):Bool
	{
		if (value == null)
			return throw new Exception("");

		var escapedKey:String = escape(key);

		var valueBytes:Bytes = Bytes.ofString(value, UTF8);
		var escapedValue:String = "'" + Base64.encode(valueBytes) + "'";

		if (!mutexAcquiredInParent)
			mutex.acquire();

		try
		{
			var connection:Connection = getConnection();
			connection.request('BEGIN TRANSACTION');
			var result:ResultSet = connection.request('SELECT value FROM $escapedTable WHERE key = $escapedKey');
			if (result.results().first() != null)
				connection.request('UPDATE $escapedTable SET value = $escapedValue WHERE key = $escapedKey');
			else
				connection.request('INSERT INTO $escapedTable (key, value) VALUES ($escapedKey, $escapedValue)');

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

	public function append(key:String, value:String):Bool
	{
		var escapedKey:String = escape(key);

		var valueBytes:Bytes = Bytes.ofString(value);
		var escapedValue:String = "'" + Base64.encode(valueBytes) + "'";

		mutex.acquire();

		try
		{
			var connection:Connection = getConnection();
			connection.request('INSERT INTO $escapedTable (key, value) VALUES ($escapedKey, $escapedValue)');
		}
		catch (exc:Dynamic)
		{
			trace('Failed to append value for key $key: $exc');
			mutex.release();
			return false;
		}

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

	// I believe its done everytime there is a transaction, dunno if it actually works lol
	public function save():Bool
	{
		if (!mutexAcquiredInParent)
			mutex.acquire();

		try
		{
			var connection:Connection = getConnection();
			connection.request('BEGIN TRANSACTION');
			connection.request('COMMIT');
		}
		catch (exc:Dynamic)
		{
			trace('Failed saving');
			if (!mutexAcquiredInParent)
				mutex.release();
			return false;
		}

		if (!mutexAcquiredInParent)
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
#end
