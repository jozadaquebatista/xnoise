/* xnoise-plugin-information.vala
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
 *     Jörn Magens
 */

public class Xnoise.PluginModule.Information : GLib.Object {
    private string _author;
    private string _copyright;
    private string _description;
    private string _icon;
    private string _license;
    private string _module;
    private string _name;
    private string _website;
    private string _xplug_file;
    private PluginCategory _category = PluginCategory.UNSPECIFIED;
    
    public string xplug_file        { get { return _xplug_file; } }
    public string name              { get { return _name; } }
    public string icon              { get { return _icon; } }
    public string module            { get { return _module; } }
    public string description       { get { return _description; } }
    public string website           { get { return _website; } }
    public string license           { get { return _license; } }
    public string copyright         { get { return _copyright; } }
    public string author            { get { return _author; } }
    public PluginCategory category  { get { return _category; } }

    public Information(string xplug_file) {
        this._xplug_file = xplug_file;
    }

    private const string group = "XnoisePlugin";

    public bool load_info() {
        var kf = new KeyFile();
        try    {
            kf.load_from_file(xplug_file, KeyFileFlags.NONE);
            if (!kf.has_group(group)) return false;
            _name        = kf.get_locale_string(group, "name");
            _description = kf.get_locale_string(group, "description");
            _module      = kf.get_string(group, "module");
            _icon        = kf.get_string(group, "icon");
            _author      = kf.get_string(group, "author");
            _website     = kf.get_string(group, "website");
            _license     = kf.get_string(group, "license");
            _copyright   = kf.get_string(group, "copyright");
            string cat   = kf.get_string(group, "category");
            switch(cat.down()) {
                case "music_store":
                case "music-store":
                case "musicstore":
                case "music store":
                    _category = PluginCategory.MUSIC_STORE;
                    break;
                case "album_art":
                case "album_art_provider":
                case "album-art":
                case "album art":
                    _category = PluginCategory.ALBUM_ART_PROVIDER;
                    break;
                case "lyrics_provider":
                case "lyrics":
                    _category = PluginCategory.LYRICS_PROVIDER;
                    break;
                case "user interface":
                case "gui":
                case "ui":
                    _category = PluginCategory.GUI;
                    break;
                case "additional":
                    _category = PluginCategory.ADDITIONAL;
                    break;
                default: // "unspecified"
                    _category = PluginCategory.UNSPECIFIED;
                    break;
            }
        }
        catch(FileError e) {
            print("Error plugin information: %s\n", e.message);
            return false;
        }
        catch(KeyFileError e) {
            print("Error plugin information: %s\n", e.message);
            return false;
        }
        return true;
    }
}

