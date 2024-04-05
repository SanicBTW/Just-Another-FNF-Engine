package database;

#if sys
import backend.SPromise;
import backend.io.Path;
import database.IDatabase.DBInitParams;
import database.IDatabase.DatabaseTable;
import haxe.Serializer;
import haxe.Unserializer;
import haxe.ds.DynamicMap;
import sys.FileSystem;
import sys.db.Connection;
import sys.db.ResultSet;
import sys.db.Sqlite;
import sys.thread.Mutex;
import sys.thread.Tls;

// TODO: Improve some parts of the code since this is just an adaptation from the old code

/**
 * A string-based key value store using Sqlite as backend.
 * 
 * This is expected to be thread safe.
 * 
 * @author Ceramic
 */
class SqliteImpl implements IDatabase<SqliteImpl>
{
	private static final APPEND_ENTRIES_LIMIT:Int = 128;

	private var connections:Array<Connection>;
	private var tlsConnection:Tls<Connection>;

	private var mutex:Mutex;
	private var mutexAcquiredInParent:Bool = false;

	private var params:DBInitParams;

	public var shouldPreprocess:Bool = true;

	private function getConnection():Connection
	{
		var connection:Connection = tlsConnection.value;
		if (connection == null)
		{
			connection = Sqlite.open(params.path);
			connections.push(connection);
			tlsConnection.value = connection;
		}
		return connection;
	}

	public function new(params:DBInitParams)
	{
		mutex = new Mutex();
		mutex.acquire();
		connections = [];
		tlsConnection = new Tls();
		mutex.release();

		this.params = params;

		if (!FileSystem.exists(Path.directory(params.path)))
			FileSystem.createDirectory(Path.directory(params.path));
	}

	public function connect():SPromise<SqliteImpl>
	{
		for (table in params.tables)
		{
			this.createTable(table);
		}

		return SPromise.resolve(this);
	}

	public function set(table:DatabaseTable, key:String, value:Any):SPromise<Bool>
	{
		if (value == null)
			return remove(table, key);

		return new SPromise<Bool>((resolve, reject) ->
		{
			var escapedTable:String = escape(table);
			var escapedKey:String = escape(key);
			var escapedValue:String = '\"${preprocessor(value, false)}\"';

			if (!mutexAcquiredInParent)
				mutex.acquire();

			try
			{
				var connection:Connection = getConnection();
				connection.request('BEGIN TRANSACTION');
				connection.request('INSERT OR REPLACE INTO $escapedTable (key, value) VALUES ($escapedKey, $escapedValue)');
				connection.request('COMMIT');
				resolve(true);
			}
			catch (ex:Dynamic)
			{
				log('Failed to set value in $table for key $key: $ex');
				if (!mutexAcquiredInParent)
					mutex.release();
				reject(ex);
			}

			if (!mutexAcquiredInParent)
				mutex.release();
		});
	}

	public function remove(table:DatabaseTable, key:String):SPromise<Bool>
	{
		return new SPromise<Bool>((resolve, reject) ->
		{
			var escapedTable:String = escape(table);
			var escapedKey:String = escape(key);

			if (!mutexAcquiredInParent)
				mutex.acquire();

			try
			{
				var connection:Connection = getConnection();
				connection.request('DELETE FROM $escapedTable WHERE key = $escapedKey');
				resolve(true);
			}
			catch (ex:Dynamic)
			{
				log('Failed to remove value in $table for key $key: $ex');
				if (!mutexAcquiredInParent)
					mutex.release();
				reject(ex);
			}

			if (!mutexAcquiredInParent)
				mutex.release();
		});
	}

	public function get(table:DatabaseTable, key:String):SPromise<Any>
	{
		return new SPromise<Any>((resolve, reject) ->
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
					res = preprocessor(entry.value, true);
					numEntries++;
				}

				resolve(res);
			}
			catch (ex:Dynamic)
			{
				log('Failed to get value in $table for key $key: $ex');
				mutex.release();
				reject(ex);
			}

			if (numEntries > APPEND_ENTRIES_LIMIT)
			{
				mutexAcquiredInParent = true;
				set(table, key, res).then((_) ->
				{
					log('Edge case reached');
					mutexAcquiredInParent = false;
				});
			}

			mutex.release();
		});
	}

	public function entries(table:DatabaseTable):SPromise<DynamicMap<String, Any>>
	{
		return new SPromise<DynamicMap<String, Any>>((resolve, reject) ->
		{
			var escapedTable:String = escape(table);
			var tempMap:DynamicMap<String, Any> = new DynamicMap();
			var length:Int = 0;

			mutex.acquire();

			try
			{
				var connection:Connection = getConnection();
				var result:ResultSet = connection.request('SELECT * FROM $escapedTable ORDER BY id ASC');

				for (entry in result)
				{
					tempMap[entry.key] = entry.value;
					length++;
				}

				tempMap["length"] = length;
				resolve(tempMap);
			}
			catch (ex:Dynamic)
			{
				log('Failed to get entries from $table: $ex');
				mutex.release();
				reject(ex);
			}

			mutex.release();
		});
	}

	// Internal use only
	private function createTable(table:DatabaseTable = DatabaseTable.DEFAULT)
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

			if (!FileSystem.exists(params.path))
				connection.request('CREATE INDEX key_idx ON $escapedTable(key)');

			connection.request('COMMIT');

			log('Created $table at ${Path.withoutDirectory(params.path)}');
		}
		catch (ex:Dynamic)
		{
			log('Failed to create $table at ${params.path}: $ex');
			mutex.release();
		}

		mutex.release();
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

	private function log(v:String)
	{
		#if debug
		trace('Sqlite Impl > $v');
		#end
	}

	private function preprocessor(v:Any, isGet:Bool):Any
		return (isGet) ? Unserializer.run(v) : Serializer.run(v);

	private static inline function escape(token:String):String
		return "'" + StringTools.replace(token, "'", "''") + "'";
}
#end
