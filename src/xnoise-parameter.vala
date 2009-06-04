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

public class Xnoise.Params : GLib.Object, IParameter { //TODO: Rename Interface nd class
	private static Params _instance;
	private SList<IParameter> IParameter_impls;
	public int posX         { get; set; default = 300;}
	public int posY         { get; set; default = 300;}
	public int winWidth     { get; set; default = 1000;}
	public int winHeight    { get; set; default = 500;}
	public bool winMaxed    { get; set; default = false;}

	public Params() {
			IParameter_impls = new GLib.SList<IParameter>();
			data_register(this);
	}

	public static Params instance() {
		if (_instance == null) _instance = new Params();
		return _instance;
	}

	private string _build_file_name() {
		_create_file_folder();
		return GLib.Path.build_filename(GLib.Environment.get_home_dir(), ".xnoise/xnoise.conf", null);
	}

	private void _create_file_folder() { 
		string SettingsFolder = GLib.Path.build_filename(GLib.Environment.get_home_dir(), ".xnoise", null);
		string SettingsKeyFile = GLib.Path.build_filename(GLib.Environment.get_home_dir(), ".xnoise/xnoise.conf", null);
		if (FileUtils.test(SettingsFolder, FileTest.EXISTS) == false) {
			DirUtils.create(SettingsFolder, 0700);
		}
		if (FileUtils.test(SettingsKeyFile, FileTest.EXISTS) == false) {
//			File.create(SettingsKeyFile, 0700); TODO
		}
	}

	public void data_register(IParameter iparam) {
		IParameter_impls.remove(iparam);
		IParameter_impls.append(iparam);
	}

	public void read_from_file_for_single(IParameter iparam) {
		KeyFile file;
		file = new GLib.KeyFile();
		try {
			string filename = _build_file_name();
			file.load_from_file(filename, GLib.KeyFileFlags.NONE);
		} catch (GLib.Error ex) {
			return;
		}
		try {
			iparam.read_data(file);
		} 
		catch (GLib.KeyFileError e) {
			stderr.printf("Error reading single\n");
			stderr.printf("%s\n", e.message);
		}
	}
	
	public void write_to_file_for_single(IParameter iparam) {
		FileStream stream = GLib.FileStream.open(_build_file_name(), "w");
		uint length;
		KeyFile file = new GLib.KeyFile();
		foreach (weak IParameter c in IParameter_impls) {
			c.write_data(file);
		}
		iparam.write_data(file);
		stream.puts(file.to_data(out length));
	}

	public void read_from_file() {
		KeyFile file;
		file = new GLib.KeyFile();
		try {
			string filename = _build_file_name();
			file.load_from_file(filename, GLib.KeyFileFlags.NONE);
		} catch (GLib.Error ex) {
			return;
		}
		foreach(weak IParameter ip in IParameter_impls) {
			try {
				ip.read_data(file);
			} 
			catch (GLib.KeyFileError e) {
			}
		}
	}

	public void write_to_file() {
		FileStream stream = GLib.FileStream.open(_build_file_name(), "w");
		uint length;
		KeyFile file = new GLib.KeyFile();
		foreach (weak IParameter c in IParameter_impls) {
			c.write_data(file);
		}
		stream.puts(file.to_data(out length));
	}

	public void read_data(KeyFile file) throws KeyFileError {
	}

	public void write_data(KeyFile file) {
	}
}

