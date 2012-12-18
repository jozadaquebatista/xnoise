/* xnoise-generic-player-tree-view.vala
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
using Xnoise.ExtDev;

private class Xnoise.ExtDev.GenericPlayerTreeView : PlayerTreeView {

    public GenericPlayerTreeView(PlayerDevice audio_player_device,
                                 Cancellable cancellable) {
        base(audio_player_device, cancellable);
    }
    
    protected override PlayerTreeStore? get_tree_store() {
        File b = File.new_for_uri(audio_player_device.get_uri());
        assert(b != null);
        b = b.get_child("Music");
        assert(b != null);
        assert(b.get_path() != null);
        File[] ba = new File[1];
        ba[0] = b;
        if(b.query_exists(null))
            return new AndroidPlayerTreeStore(this, audio_player_device, ba, cancellable);
        else {
            b = File.new_for_uri(audio_player_device.get_uri());
            b = b.get_child("media"); // old android devices
            return new AndroidPlayerTreeStore(this, audio_player_device, ba, cancellable);
        }
    }
    
    protected override File? get_dest_dir() {
        GenericPlayerDevice? g = audio_player_device as GenericPlayerDevice;
        assert(g != null);
        File dest_base = File.new_for_uri(g.player_folders[0]);
        assert(dest_base != null);
        return dest_base;
    }
}

