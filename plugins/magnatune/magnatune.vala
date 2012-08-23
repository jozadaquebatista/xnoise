/* magnatune.vala
 *
 * Copyright (C) 2012  Jörn Magens
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
 *     Jörn Magens <shuerhaaken@googlemail.com>
 */

using Gtk;
using Gdk;

using Xnoise;
using Xnoise.Resources;
using Xnoise.PluginModule;


private static const string MAGNATUNE_MUSIC_STORE_NAME = "MagnatuneMusicStore";

public class MagnatunePlugin : GLib.Object, IPlugin {
    public Main xn { get; set; }
    
    private unowned PluginModule.Container _owner;
    private MagMusicStore music_store;

    public PluginModule.Container owner {
        get { return _owner;  }
        set { _owner = value; }
    }
    
    public string name { get { return "magnatune_music_store"; } }
    
    public bool init() {
        this.music_store = new MagMusicStore();//this);
        owner.sign_deactivated.connect(clean_up);
        return true;
    }
    
    public void uninit() {
        clean_up();
    }

    private void clean_up() {
        owner.sign_deactivated.disconnect(clean_up);
        music_store = null;
    }

    public Gtk.Widget? get_settings_widget() {
        return null;
    }

    public bool has_settings_widget() {
        return false;
    }
}



//The Magnatune Music Store.
private class MagMusicStore : GLib.Object {
    private DockableMagnatuneMS msd;
    
    public MagMusicStore() {
        msd = new DockableMagnatuneMS();
        main_window.msw.insert_dockable(msd);
    }
    
    ~MagMusicStore() {
        main_window.msw.select_dockable_by_name("MusicBrowserDockable");
        if(msd == null)
            return;
        if(msd.action_group != null) {
            main_window.ui_manager.remove_action_group(msd.action_group);
        }
        if(msd.ui_merge_id != 0)
            main_window.ui_manager.remove_ui(msd.ui_merge_id);
        main_window.msw.remove_dockable_in_idle(MAGNATUNE_MUSIC_STORE_NAME);
    }
}


