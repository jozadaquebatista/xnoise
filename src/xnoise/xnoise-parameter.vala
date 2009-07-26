/* xnoise-parameter.vala
 *
 * Copyright (C) 2009  Jörn Magens
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

using GLib;

public class Xnoise.Params : GLib.Object { //TODO: Rename Interface nd class
	private const string INIFILE   = "xnoise.ini";
	private const string INIFOLDER = ".xnoise";
	private List<IParams> IParams_implementers = new GLib.List<IParams>();
	private const string settings_int    = "settings_int";
	private const string settings_double = "settings_double";
	private const string settings_string = "settings_string";
	private GLib.HashTable<string,int> ht_int        = new GLib.HashTable<string,int>(str_hash, str_equal);
	private GLib.HashTable<string,double?> ht_double = new GLib.HashTable<string,double?>(str_hash, str_equal);
	private GLib.HashTable<string,string> ht_string  = new GLib.HashTable<string,string>(str_hash, str_equal);

	public Params() {
		read_all_parameters_from_file(); //Fill hash tables on construction time
	}

	public void data_register(IParams iparam) {
		//Each IParams interface implementor goes to the List
		IParams_implementers.remove(iparam); //..and shouldn't be doubled
		IParams_implementers.append(iparam);
	}

	private void read_all_parameters_from_file() {
		//Put all values to hashtables on startup
		KeyFile kf = new GLib.KeyFile();
		try {
			kf.load_from_file(build_file_name(), 
			                  GLib.KeyFileFlags.NONE);
			//write settings of type integer to hashtable
			string[] groups;
			groups = kf.get_keys(settings_int);
			foreach(string s in groups) {
				ht_int.insert(s, kf.get_integer(settings_int, s));
			}
			//write settings of type double to hashtable
			groups = kf.get_keys(settings_double);
			foreach(string s in groups) {
				ht_double.insert(s, kf.get_double(settings_double, s));
			}			
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
		foreach(weak IParams ip in IParams_implementers) {
			ip.read_params_data();
		}
	}

	public void write_all_parameters_to_file() {
		FileStream stream = GLib.FileStream.open(build_file_name(), "w");
		size_t length;
		KeyFile kf = new GLib.KeyFile();
		foreach(weak IParams ip in IParams_implementers) {
			ip.write_params_data();
		}
		foreach(string key in ht_int.get_keys()) {
			kf.set_integer(settings_int, key, ht_int.lookup(key));
		}
		foreach(string key in ht_double.get_keys()) {
			kf.set_double(settings_double, key, ht_double.lookup(key));
		}
		foreach(string key in ht_string.get_keys()) {
			kf.set_string(settings_string, key, ht_string.lookup(key));
		}
		stream.puts(kf.to_data(out length));
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
		if(buffer==null) { //because split doesn't like null strings
			return null;
		}
		string[] list = (buffer).split(";", 50);
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
	public void set_string_list_value(string key, string[] value) {
		string? buffer = null;
		foreach(string s in value) {
			if(buffer == null) {
				buffer = s;
				continue;
			}
			buffer = buffer + ";" + s;
		}
		if(buffer!=null) ht_string.insert(key,buffer);
	}
	//Type string
	public void set_string_value(string key, string value) {
		ht_string.insert(key,value);
	}



	private string build_file_name() {
		if(!create_file_folder()) {
			print("Error with creating configuration directory.\n");
		}
		return GLib.Path.build_filename(GLib.Environment.get_home_dir(), INIFOLDER, INIFILE, null);
	}
	
	private bool create_file_folder() { 
		File home_dir = File.new_for_path(Environment.get_home_dir());
		File xnoise_home = home_dir.get_child(".xnoise");
		if (!xnoise_home.query_exists(null)) {
			try {
				File current_dir = xnoise_home;
				File[] directory_list = {};
				while(current_dir != null) {
				    if(current_dir.query_exists(null)) break;
					directory_list += current_dir;
				    current_dir = current_dir.get_parent();
				}
				foreach(File dir in directory_list) {
				    dir.make_directory(null);
				}
			} 
			catch (Error e) {
				stderr.printf("Error with create directory: %s", e.message);
				return false;
			}
		}
		return true;
	}
}

