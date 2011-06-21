/* xnoise-db-creator.vala
 *
 * Copyright (C) 2009-2011  Jörn Magens
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  The Xnoise authors hereby grant permission for non-GPL compatible
 *  GStreamer plugins to be used and distributed together with GStreamer
 *  and Xnoise. This permission is above and beyond the permissions granted
 *  by the GPL license by which Xnoise is covered. If you modify this code
 *  you may extend this exception to your version of the code, but you are not
 *  obligated to do so. If you do not wish to do so, delete this exception
 *  statement from your version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301  USA.
 *
 * Author:
 * 	Jörn Magens
 */

using Sqlite;

private class Xnoise.DbCreator {
	private static const string DATABASE_NAME = "db.sqlite";
	private static const string SETTINGS_FOLDER = ".xnoise";
	public static const int DB_VERSION_MAJOR = 4;
	public static const int DB_VERSION_MINOR = 1;

	private static Sqlite.Database? db;
	private static File? xnoisedb;

	//CREATE TABLE STATEMENTS
	private static const string STMT_CREATE_LASTUSED =
		"CREATE TABLE lastused(uri TEXT, mediatype INTEGER, id INTEGER);";
	private static const string STMT_CREATE_MEDIAFOLDERS =
		"CREATE TABLE media_folders(name TEXT PRIMARY KEY);";
	private static const string STMT_CREATE_MEDIAFILES =
		"CREATE TABLE media_files(name TEXT PRIMARY KEY);";
	private static const string STMT_CREATE_RADIO =
		"CREATE TABLE streams (id INTEGER PRIMARY KEY, name TEXT, uri TEXT);";
	private static const string STMT_CREATE_ARTISTS =
		"CREATE TABLE artists (id INTEGER PRIMARY KEY, name TEXT);";
	private static const string STMT_CREATE_ALBUMS =
		"CREATE TABLE albums (id INTEGER PRIMARY KEY, artist INTEGER, name TEXT, image TEXT);";
	private static const string STMT_CREATE_URIS =
		"CREATE TABLE uris (id INTEGER PRIMARY KEY, name TEXT, type INTEGER);";
	private static const string STMT_CREATE_GENRES =
		"CREATE TABLE genres (id integer primary key, name TEXT);";
	private static const string STMT_CREATE_ITEMS =
		"CREATE TABLE items (id INTEGER PRIMARY KEY, tracknumber INTEGER, artist INTEGER, album INTEGER, title TEXT, genre INTEGER, year INTEGER, uri INTEGER, mediatype INTEGER, length INTEGER, bitrate INTEGER, usertags TEXT, playcount INTEGER, rating INTEGER, lastplayTime DATETIME, addTime DATETIME, CONSTRAINT link_uri FOREIGN KEY (uri) REFERENCES uris(id) ON DELETE CASCADE);";
	//TODO: Is genre not used?
//CREATE TABLE test1 (id INTEGER PRIMARY KEY, tracknumber INTEGER, artist INTEGER, album INTEGER, title TEXT, genre INTEGER, year INTEGER, uri INTEGER REFERENCES uris(id) ON DELETE CASCADE, mediatype INTEGER, length INTEGER, bitrate INTEGER, usertags TEXT, playcount INTEGER, rating INTEGER, lastplayTime DATETIME, addTime DATETIME);
	private static const string STMT_CREATE_VERSION =
		"CREATE TABLE version (major INTEGER, minor INTEGER);";
	private static const string STMT_GET_VERSION =
		"SELECT major FROM version;";

	//FIND TABLE
	private static const string STMT_FIND_TABLE =
		"SELECT name FROM sqlite_master WHERE type='table' ORDER BY name;";

	private static void setup_db_handle() {
		//TODO: Version check with drop table
		File xnoise_home = File.new_for_path(global.settings_folder);
		xnoisedb = xnoise_home.get_child(DATABASE_NAME);
		if(!xnoise_home.query_exists(null)) {
			try {
				xnoise_home.make_directory_with_parents(null);
			}
			catch(Error e) {
				print("%s\n", e.message);
			}
		}
		Database.open_v2(xnoisedb.get_path(),
		                 out db,
		                 Sqlite.OPEN_CREATE|Sqlite.OPEN_READWRITE,
		                 null) ;
	}

	private static bool exec_stmnt_string(string statement) {
		string errormsg;
		if(db.exec(statement, null, out errormsg)!= Sqlite.OK) {
			stderr.printf("exec_stmnt_string error: %s", errormsg);
			return false;
		}
		return true;
	}

	private static void reset() {
		db = null;
		xnoisedb = null;
	}
	
	public static void check_tables(ref bool is_first_start) {
		if(db == null)
			setup_db_handle();
		
		if(db == null) {
			print("Cannot create database.\n");
			reset();
			return;
		}
		
		if(xnoisedb.query_exists(null)) {
			bool db_table_exists = false;
			Statement stmt;
			
			db.prepare_v2(STMT_FIND_TABLE, -1, out stmt);
			stmt.reset();
			while(stmt.step() == Sqlite.ROW) {
				if(stmt.column_text(0)=="version") {
					db_table_exists = true;
					break;
				}
			}
			if(db_table_exists == true) {
				db.prepare_v2(STMT_GET_VERSION, -1, out stmt);
				stmt.reset();
				while(stmt.step() == Sqlite.ROW) {
					if(stmt.column_int(0) != DB_VERSION_MAJOR) {
						print("Wrong major db version\n");
						//newly create db if major version is devating
						db = null;
						is_first_start = true;
						try { 
							xnoisedb.delete(null);
						}
						catch(Error e) {
							print("%s\n", e.message);
						}
						check_tables(ref is_first_start);
						reset();
						return;
					}
				}
			}
			else {
			//create Tables if not existant
				if(!exec_stmnt_string(STMT_CREATE_LASTUSED)     ) { reset(); return; }
				if(!exec_stmnt_string(STMT_CREATE_MEDIAFOLDERS) ) { reset(); return; }
				if(!exec_stmnt_string(STMT_CREATE_MEDIAFILES)   ) { reset(); return; }
				if(!exec_stmnt_string(STMT_CREATE_RADIO)        ) { reset(); return; }
				if(!exec_stmnt_string(STMT_CREATE_ARTISTS)      ) { reset(); return; }
				if(!exec_stmnt_string(STMT_CREATE_ALBUMS)       ) { reset(); return; }
				if(!exec_stmnt_string(STMT_CREATE_URIS)         ) { reset(); return; }
				if(!exec_stmnt_string(STMT_CREATE_ITEMS)        ) { reset(); return; }
				if(!exec_stmnt_string(STMT_CREATE_GENRES)       ) { reset(); return; }
				if(!exec_stmnt_string(STMT_CREATE_VERSION)      ) { reset(); return; }
				//Set database version
				exec_stmnt_string("INSERT INTO version (major, minor) VALUES (%d, %d);".printf(DB_VERSION_MAJOR, DB_VERSION_MINOR));
			}
		}
		else {
			print("Could not create or open database.\n");
		}
		reset();
	}
}

