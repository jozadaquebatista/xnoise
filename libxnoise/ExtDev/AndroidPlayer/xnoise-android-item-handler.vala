/* xnoise-android-item-handler.vala
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
 *     Jörn Magens
 */


using Xnoise;
using Xnoise.ExtDev;


// ItemHandler Implementation 
// provides the right Action for the given ActionContext/ItemType
private class Xnoise.HandlerAndroidDevice : ItemHandler {
    private Action a;
    private static const string ainfo = _("Add to Android Device");
    private static const string aname = "A HandlerAndroidDevicename";
    
    private unowned AndroidPlayerDevice audio_player_device;
    private unowned Cancellable cancellable;
    private string name;
    
    public HandlerAndroidDevice(AndroidPlayerDevice audio_player_device,
                                Cancellable cancellable) {
        this.audio_player_device = audio_player_device;
        this.cancellable = cancellable;
        name = audio_player_device.get_identifier();
        
        a = new Action();
        a.action = add_to_device;
        a.info = ainfo;
        a.name = aname;
        a.stock_item = Gtk.Stock.OPEN;
        a.context = ActionContext.QUERYABLE_TREE_MENU_QUERY;
        
    }

    public override ItemHandlerType handler_type() {
        return ItemHandlerType.EXTERNAL_DEVICE;
    }
    
    public override unowned string handler_name() {
        return name;
    }

    public override unowned Action? get_action(ItemType type,
                                               ActionContext context,
                                               ItemSelectionType selection = ItemSelectionType.NOT_SET) {
        if(context == ActionContext.QUERYABLE_TREE_MENU_QUERY)
            return a;
        
        return null;
    }

    private void add_to_device(Item item, GLib.Value? data, GLib.Value? data2) { 
        if(cancellable.is_cancelled())
            return;
        
        if(item.type != ItemType.LOCAL_AUDIO_TRACK && item.type != ItemType.LOCAL_VIDEO_TRACK) 
            return;
        if(item.uri == null || item.uri == "")
            return;
        
        TreeQueryable? tq = data as TreeQueryable;
        if(tq == null)
            return;
        if(!(tq is TreeQueryable))
            return;
        
        print("ADD TO ANDROID\n");
        var job = new Worker.Job(Worker.ExecutionType.ONCE, copy_file_job);
        job.item = item;
        device_worker.push_job(job);
    }
    
    private bool copy_file_job(Worker.Job job) {
        if(cancellable.is_cancelled())
            return false;
        if(!(this.audio_player_device is IAudioPlayerDevice))
            return false;
        File s = File.new_for_uri(job.item.uri);
        FileInfo info = null;
        try {
            info = s.query_info(FileAttribute.STANDARD_SIZE, FileQueryInfoFlags.NONE, cancellable);
        }
        catch(Error e) {
            print("%s\n", e.message);
            return false;
        }
        uint64 size = info.get_attribute_uint64(FileAttribute.STANDARD_SIZE);
        if(this.audio_player_device.get_free_space_size() < size) {
            print("not enough space on device!\n");
        }
        else {
            File dest = File.new_for_uri(this.audio_player_device.get_uri());
            assert(dest != null);
            File dest1 = dest.get_child("Music");
            assert(dest != null);
            if(!dest1.query_exists(cancellable)) {
                dest1 = dest.get_child("media");
            }
            dest = dest1.get_child(s.get_basename());
            assert(dest != null);
            print("dest : %s\n", dest.get_path());
            try {
                s.copy(dest, FileCopyFlags.NONE, cancellable, null);
            }
            catch(Error e) {
                print("%s\n", e.message);
                return false;
            }
            print("done copying file to android device.\n");
            Idle.add(() => {
                if(cancellable.is_cancelled())
                    return false;
                audio_player_device.sign_add_track(dest.get_uri());
                return false;
            });
        }
        return false;
    }
}

