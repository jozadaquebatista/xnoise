/* xnoise-plugin-information.vala
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

public class Xnoise.PluginInformation : GLib.Object {
	public string xplug_file  { get; private set; }
	public string name        { get; private set; }
	public string icon        { get; private set; }
	public string module      { get; private set; }
	public string description { get; private set; }
	public string website     { get; private set; }
	public string license     { get; private set; }
	public string copyright   { get; private set; }
	public string author      { get; private set; }
	
	public PluginInformation(string xplug_file) {
		this.xplug_file = xplug_file;
	}
	
	private string group = "XnoisePlugin";

	public bool load_info() {
		var kf = new KeyFile();
		try	{
			kf.load_from_file(xplug_file, KeyFileFlags.NONE);
			if (!kf.has_group(group)) return false;
			name        = kf.get_string(group, "name");
			description = kf.get_string(group, "description");
			module      = kf.get_string(group, "module");
			icon        = kf.get_string(group, "icon");
			author      = kf.get_string(group, "author");
			website     = kf.get_string(group, "website");
			license     = kf.get_string(group, "license");
			copyright   = kf.get_string(group, "copyright");
			return true;
		}
		catch(KeyFileError e) {
			print("Error plugin information: %s\n", e.message);
			return false;
		}
	}
}

