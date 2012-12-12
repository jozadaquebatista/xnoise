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


private class Xnoise.HandlerAndroidDevice : ItemHandler {
    private Action a;
    private Action b;
    private static const string ainfo = _("Add to Android Device");
    private static const string aname = "A HandlerAndroidDevicename";
    
    private unowned AndroidPlayerDevice audio_player_device;
    private unowned Cancellable cancellable;
    private string name;
    private uint finish_source = 0;
    
    public HandlerAndroidDevice(AndroidPlayerDevice audio_player_device,
                                Cancellable cancellable) {
        this.audio_player_device = audio_player_device;
        this.cancellable = cancellable;
        name = audio_player_device.get_identifier();
        
        a = new Action();
        a.action = add_track_to_device;
        a.info = ainfo;
        a.name = aname;
        a.stock_item = Gtk.Stock.OPEN;
        a.context = ActionContext.QUERYABLE_TREE_MENU_QUERY;
        
        b = new Action();
        b.action = add_to_device;
        b.info = ainfo;
        b.name = aname;
        b.stock_item = Gtk.Stock.OPEN;
        b.context = ActionContext.QUERYABLE_TREE_MENU_QUERY;
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
        if(context == ActionContext.QUERYABLE_TREE_MENU_QUERY && 
           (type == ItemType.LOCAL_AUDIO_TRACK || type == ItemType.LOCAL_VIDEO_TRACK))
            return a;
        if(context == ActionContext.QUERYABLE_TREE_MENU_QUERY) {
            print("use b action\n");
            return b;
        }
        
        return null;
    }

    private void add_to_device(Item item, GLib.Value? data, GLib.Value? data2) { 
        if(cancellable.is_cancelled())
            return;
        
        TreeQueryable? tq = data as TreeQueryable;
        if(tq == null)
            return;
        if(!(tq is TreeQueryable))
            return;
        GLib.List<Gtk.TreePath> list;
        list = tq.query_selection();
        if(list.length() == 0)
            return;
        
        var mod = tq.get_queryable_model();
        Item? ix = Item(ItemType.UNKNOWN);
        Gtk.TreeIter iter;
        Item[] items = {};
        var job = new Worker.Job(Worker.ExecutionType.ONCE, prep_copy_files_job);
        foreach(Gtk.TreePath path in list) {
            mod.get_iter(out iter, path);
            mod.get(iter, tq.get_model_item_column(), out ix);
            items += ix;
        }
        job.items = items;
        db_worker.push_job(job);
    }
    
    private bool prep_copy_files_job(Worker.Job _job) {
        var job = new Worker.Job(Worker.ExecutionType.ONCE, copy_files_job);
        job.items = prepare_track_items(_job);
        device_worker.push_job(job);
        return false;
    }
    
    private Item[] prepare_track_items(Worker.Job job) {
        Item[] ia = {};
        foreach(Item? i in job.items) {
            if(i.type == ItemType.LOCAL_AUDIO_TRACK ||
               i.type == ItemType.LOCAL_VIDEO_TRACK) {
                ia += i;
                continue;
            }
            if(i.type == ItemType.COLLECTION_CONTAINER_ALBUM) {
                TrackData[] track_dat = item_converter.to_trackdata(i, global.searchtext, null);
                foreach(var td in track_dat) {
                    ia += td.item;
                }
                continue;
            }
            if(i.type == ItemType.COLLECTION_CONTAINER_ARTIST) {
                TrackData[] track_dat = item_converter.to_trackdata(i, global.searchtext, null);
                foreach(var td in track_dat) {
                    ia += td.item;
                }
                continue;
            }
        }
        return ia;
    }
    
    private void add_track_to_device(Item item, GLib.Value? data, GLib.Value? data2) { 
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
        var job = new Worker.Job(Worker.ExecutionType.ONCE, copy_files_job);
        job.items = new Item[1];
        job.items[0] = item;
        device_worker.push_job(job);
    }
    
    private bool copy_files_job(Worker.Job job) {
        if(cancellable.is_cancelled())
            return false;
        if(!(this.audio_player_device is IAudioPlayerDevice))
            return false;
        foreach(Item? it in job.items) {
            
            File s = File.new_for_uri(it.uri);
            FileInfo info = null;
            try {
                info = s.query_info(FileAttribute.STANDARD_SIZE, FileQueryInfoFlags.NONE, cancellable);
            }
            catch(Error e) {
                print("%s\n", e.message);
                continue;
            }
            uint64 size = info.get_attribute_uint64(FileAttribute.STANDARD_SIZE);
            if(this.audio_player_device.get_free_space_size() < size) {
                print("not enough space on device!\n");
                uint msg_id = 0;
                msg_id = userinfo.popup(UserInfo.RemovalType.TIMER_OR_CLOSE_BUTTON,
                                        UserInfo.ContentClass.CRITICAL,
                                        _("Not enough space on device!"),
                                        false,
                                        10,
                                        null);
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
                //print("dest : %s\n", dest.get_path());
                try {
                    s.copy(dest, FileCopyFlags.NONE, cancellable, null);
                }
                catch(Error e) {
                    print("%s\n", e.message);
                    continue;
                }
                //print("done copying file to android device.\n");
                Timeout.add(200, () => {
                    if(cancellable.is_cancelled())
                        return false;
                    audio_player_device.sign_add_track(dest.get_uri());
                    return false;
                });
            }
        }
        
        return false;
    }
}

