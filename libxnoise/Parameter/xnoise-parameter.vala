/* xnoise-parameter.vala
 *
 * Copyright (C) 2009-2012  Jörn Magens
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

using Xnoise;
using Xnoise.Services;

public class Xnoise.Params : GLib.Object { //TODO: Rename Interface nd class
	private static const string INIFILE   = "xnoise.ini";
	private static List<IParams> IParams_implementers;// = new GLib.List<IParams>();
	private static const string settings_int    = "settings_int";
	private static const string settings_double = "settings_double";
	private static const string settings_string = "settings_string";
	private static HashTable<string,int>     ht_int;
	private static HashTable<string,double?> ht_double;
	private static HashTable<string,string>  ht_string;
	private static bool inited = false;
	
	public static void init() {
		if(inited == true)
			return;
		IParams_implementers = new GLib.List<IParams>();
		ht_int    = new GLib.HashTable<string,int>(str_hash, str_equal);
		ht_double = new GLib.HashTable<string,double?>(str_hash, str_equal);
		ht_string = new GLib.HashTable<string,string>(str_hash, str_equal);
		read_all_parameters_from_file(); //Fill hash tables on construction time
		inited = true;
	}

	public static void iparams_register(IParams iparam) {
		//Each IParams interface implementor goes to the List
		IParams_implementers.remove(iparam); //..and shouldn't be doubled
		IParams_implementers.append(iparam);
	}

	private static void read_all_parameters_from_file() {
		//Put all values to hashtables on startup
		KeyFile kf = new GLib.KeyFile();
		try {
			string? path = build_file_name();
			if(path==null) {
				print("Cannot get keyfile\n");
				return;
			}
			kf.load_from_file(path, GLib.KeyFileFlags.NONE);
			//write settings of type integer to hashtable
			string[] groups;
			groups = kf.get_keys(settings_int);
			foreach(string s in groups)
				ht_int.insert(s, kf.get_integer(settings_int, s));
			//write settings of type double to hashtable
			groups = kf.get_keys(settings_double);
			foreach(string s in groups)
				ht_double.insert(s, kf.get_double(settings_double, s));
			//write settings of type string to hashtable
			groups = kf.get_keys(settings_string);
			foreach(string s in groups) {
				ht_string.insert(s, kf.get_string(settings_string, s));
			}
		}
		catch(GLib.Error ex) {
			return;
		}
	}

	public static void set_start_parameters_in_implementors() {
		foreach(unowned IParams ip in IParams_implementers) {
			ip.read_params_data();
		}
	}

	public static void write_all_parameters_to_file() {
		size_t length;
		
		KeyFile kf = new GLib.KeyFile();
		
		foreach(IParams ip in IParams_implementers) {
			if(ip != null) 
				ip.write_params_data();
		}
		
		foreach(string key in ht_int.get_keys())
			kf.set_integer(settings_int, key, ht_int.lookup(key));
		
		foreach(string key in ht_double.get_keys())
			kf.set_double(settings_double, key, ht_double.lookup(key));
		
		foreach(string key in ht_string.get_keys())
			kf.set_string(settings_string, key, ht_string.lookup(key));
		
		File f = File.new_for_path(build_file_name());
		try {
			var fs = f.replace(null, false, FileCreateFlags.NONE, null);
			var ds = new DataOutputStream(fs);
			ds.put_string(kf.to_data(out length), null);
		}
		catch(GLib.Error e) {
			print("%s\n", e.message);
		}
	}


	//  GETTERS FOR THE HASH TABLE
	//Type int
	public static int get_int_value(string key) {
		int val = ht_int.lookup(key);
		if(val!=0)
			return val;
		else
			return 0;
	}
	//Type double
	public static double get_double_value(string key) {
		double? val = ht_double.lookup(key);
		if(val!=null)
			return val;
		else
			return 0.0;
	}
	//Type string list
	public static string[]? get_string_list_value(string key) {
		string? buffer = ht_string.lookup(key);
		if((buffer==null)||(buffer=="#00"))
			return null;
		string[] list = buffer.split(";", 50);
		return list;
	}
	//Type string
	public static string get_string_value(string key) {
		string val = ht_string.lookup(key);
		return val == null ? EMPTYSTRING : val;
	}



	//  SETTERS FOR THE HASH TABLE
	//Type int
	public static void set_int_value(string key, int value) {
		ht_int.insert(key,value);
	}
	//Type double
	public static void set_double_value(string key, double value) {
		ht_double.insert(key,value);
	}
	//Type string list
	public static void set_string_list_value(string key, string[]? value) {
		string? buffer = null;
		if(value!=null) {
			foreach(string s in value) {
				if(buffer==null) {
					buffer = s;
					continue;
				}
				buffer = buffer + ";" + s;
			}
		}
		else {
			buffer = "#00";
		}

		if(buffer!=null) ht_string.insert(key,buffer);
	}
	//Type string
	public static void set_string_value(string key, string value) {
		ht_string.insert(key,value);
	}

	private static string? build_file_name() {
		File f = File.new_for_path(GLib.Path.build_filename(settings_folder(), INIFILE, null));
		return create_default_if_not_exist(f);
	}

	private static string? create_default_if_not_exist(File f) {
		if(!f.query_exists(null)) {
			try {
				var fs = f.create(FileCreateFlags.NONE, null);
				var ds = new DataOutputStream(fs);
				ds.put_string(default_content, null);
			}
			catch(GLib.Error e) {
				print("%s\n", e.message);
			}
		}
		return f.get_path();
	}

// default parameter set (used if nothing else is available)
private static const string default_content = 
"""[settings_int]
usestop=1
position_title_column=3
hp_position=255
not_show_art_on_hover_image=1
position_album_column=4
position_artist_column=5
use_tracknumber_column=1
repeatstate=2
posY=129
quit_if_closed=0
posX=579
compact_layout=1
height=599
position_#_column=2
width=1179
use_treelines=0
use_album_column=1
position_genre_column=8
use_linebreaks=1
fontsizeMB=10
use_year_column=0
position_tracknumber_column=2
use_length_column=1
position_status-icon_column=1
use_artist_column=1
position_year_column=7
position_length_column=6

[settings_double]
volume=0.33594936708860756

[settings_string]
activated_plugins=DatabaseLyrics;notifications;Lyricwiki;chartlyrics;CyclicSaveState;mediakeys;LastfmCovers;azlyrics
""";
}

