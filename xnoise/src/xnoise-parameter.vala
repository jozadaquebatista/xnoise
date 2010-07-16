/* xnoise-parameter.vala
 *
 * Copyright (C) 2009-2010  Jörn Magens
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

public class Xnoise.Params : GLib.Object { //TODO: Rename Interface nd class
	private const string INIFILE   = "xnoise.ini";
	private const string INIFOLDER = ".xnoise";
	private List<IParams> IParams_implementers = new GLib.List<IParams>();
	private const string settings_int    = "settings_int";
	private const string settings_double = "settings_double";
	private const string settings_string = "settings_string";
	private GLib.HashTable<string,int>     ht_int    = new GLib.HashTable<string,int>(str_hash, str_equal);
	private GLib.HashTable<string,double?> ht_double = new GLib.HashTable<string,double?>(str_hash, str_equal);
	private GLib.HashTable<string,string>  ht_string = new GLib.HashTable<string,string>(str_hash, str_equal);

	public Params() {
		read_all_parameters_from_file(); //Fill hash tables on construction time
	}

	public void iparams_register(IParams iparam) {
		//Each IParams interface implementor goes to the List
		IParams_implementers.remove(iparam); //..and shouldn't be doubled
		IParams_implementers.append(iparam);
	}

	private void read_all_parameters_from_file() {
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

	public void set_start_parameters_in_implementors() {
		foreach(unowned IParams ip in IParams_implementers) {
			ip.read_params_data();
		}
	}

	public void write_all_parameters_to_file() {
		size_t length;

		KeyFile kf = new GLib.KeyFile();
		
		foreach(unowned IParams ip in IParams_implementers) {
			if(ip != null) ip.write_params_data();
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
	public int get_int_value(string key) {
		int? val = ht_int.lookup(key);
		if(val!=null)
			return val;
		else
			return 0;
	}
	//Type double
	public double get_double_value(string key) {
		double? val = ht_double.lookup(key);
		if(val!=null)
			return val;
		else
			return 0.0;
	}
	//Type string list
	public string[]? get_string_list_value(string key) {
		string? buffer = ht_string.lookup(key);
		if((buffer==null)||(buffer=="#00"))
			return null;
		string[] list = buffer.split(";", 50);
		return list;
	}
	//Type string
	public string get_string_value(string key) {
		string val = ht_string.lookup(key);
		return val == null ? "" : val;
	}



	//  SETTERS FOR THE HASH TABLE
	//Type int
	public void set_int_value(string key, int value) {
		ht_int.insert(key,value);
	}
	//Type double
	public void set_double_value(string key, double value) {
		ht_double.insert(key,value);
	}
	//Type string list
	public void set_string_list_value(string key, string[]? value) {
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
	public void set_string_value(string key, string value) {
		ht_string.insert(key,value);
	}

	public int get_lyric_provider_priority(string name) {
		string[]? prio_order = get_string_list_value("prio_lyrics");
		if(prio_order == null)
			return 99;
		
		int i = 0;
		foreach(string s in prio_order) {
			if(name == s)
				return i;
			else
				i++;
		}
		
		return i;
	}
	
	public int get_image_provider_priority(string name) {
		string[]? prio_order = get_string_list_value("prio_images");
		if(prio_order == null)
			return 99;
		
		int i = 0;
		foreach(string s in prio_order) {
			if(name == s)
				return i;
			else
				i++;
		}
		
		return i;
	}

	private string? build_file_name() {
		if(!check_file_folder())
			print("Error with creating configuration directory.\n");
		string fname = GLib.Path.build_filename(global.settings_folder, INIFILE, null);
		File f = File.new_for_path(fname);
		return create_default_if_not_exist(f);
	}

	private string? create_default_if_not_exist(File f) {
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

	private bool check_file_folder() {
		File xnoise_home = File.new_for_path(global.settings_folder);
		if(!xnoise_home.query_exists(null)) {
			try {
				xnoise_home.make_directory_with_parents(null);
			}
			catch(Error e) {
				print("%s\n", e.message);
			}
		}
		return true;
	}

private const string default_content = """
[settings_int]
use_lyrics=1
use_length_column=1
use_album_column=1
posY=0
posX=0
height=550
fontsizeMB=8
compact_layout=1
width=1116
use_tracknumber_column=0
hp_position=241
use_treelines=0
show_album_images=1
repeatstate=2

[settings_double]
volume=0.080511778431618983

[settings_string]
prio_lyrics=Leoslyrics;Lyricsfly
prio_images=LastfmCovers
activated_plugins=Chartlyrics;notifications;LastfmCovers;TitleToDecoration;Mediawatcher;mediakeys
""";
}

