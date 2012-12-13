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
using Xnoise.Resources;


private class Xnoise.HandlerAndroidDevice : ItemHandler {
    private Action a;
//    private Action b;
    private Action c;
    private static const string ainfo = _("Add to Android Device");
    private static const string aname = "A HandlerAndroidDevicename";
    private static const string cinfo = _("Delete from device");
    private static const string cname = "C HandlerAndroidDevicename";
    
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
        a.action = add_to_device;
        a.info = ainfo;
        a.name = aname;
        a.stock_item = Gtk.Stock.OPEN;
        a.context = ActionContext.QUERYABLE_TREE_MENU_QUERY;
        
//        b = new Action();
//        b.action = add_to_device;
//        b.info = ainfo;
//        b.name = aname;
//        b.stock_item = Gtk.Stock.OPEN;
//        b.context = ActionContext.QUERYABLE_TREE_MENU_QUERY;
        
        c = new Action();
        c.action = delete_from_device;
        c.info = cinfo;
        c.name = cname;
        c.stock_item = Gtk.Stock.DELETE;
        c.context = ActionContext.EXTERNAL_DEVICE_LIST;
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
        if(context == ActionContext.QUERYABLE_TREE_MENU_QUERY) {
            if(audio_player_device.in_loading)
                return null;
            return a;
        }
        if(context == ActionContext.EXTERNAL_DEVICE_LIST) {
            if(audio_player_device.in_loading)
                return null;
            return c;
        }
        
        return null;
    }
    
    private void delete_from_device(Item item, GLib.Value? data, GLib.Value? data2) {
        if(cancellable.is_cancelled())
            return;
        if(item.type == ItemType.LOCAL_AUDIO_TRACK || item.type == ItemType.LOCAL_VIDEO_TRACK) {
            var msg = new Gtk.MessageDialog(main_window, Gtk.DialogFlags.MODAL, Gtk.MessageType.QUESTION,
                                            Gtk.ButtonsType.OK_CANCEL,
                                            _("Do you want to delete the selected file from the device?"));
            msg.response.connect( (s, response_id) => {
                //print("response id %d\n", response_id);
                if((Gtk.ResponseType)response_id == Gtk.ResponseType.OK) {
                    try {
                        File f = File.new_for_uri(item.uri);
                        f.delete(cancellable);
                        delete_from_database(item);
                        var job = new Worker.Job(Worker.ExecutionType.ONCE, on_delete_finished);
                        db_worker.push_job(job);
                    }
                    catch(GLib.Error e) {
                        print("%s\n", e.message);
                    }
                }
                s.destroy();
            });
            msg.run();
        }
        else if(item.type == ItemType.COLLECTION_CONTAINER_ALBUM) {
            var msg = new Gtk.MessageDialog(main_window, Gtk.DialogFlags.MODAL, Gtk.MessageType.QUESTION,
                                            Gtk.ButtonsType.OK_CANCEL,
                                            _("Do you want to delete the selected album from the device?"));
            msg.response.connect( (s, response_id) => {
                //print("response id %d\n", response_id);
                if((Gtk.ResponseType)response_id == Gtk.ResponseType.OK) {
                    HashTable<ItemType,Item?>? items = new HashTable<ItemType,Item?>(direct_hash, direct_equal);
                    items.insert(item.type, item);
                    TrackData[] tda = 
                        audio_player_device.db.get_trackdata_for_album(EMPTYSTRING,
                                                                       CollectionSortMode.ARTIST_ALBUM_TITLE,
                                                                       items);
                    foreach(TrackData td in tda) {
                        try {
                            File f = File.new_for_uri(td.item.uri);
                            f.delete(cancellable);
                            delete_from_database(td.item);
                        }
                        catch(GLib.Error e) {
                            print("%s\n", e.message);
                        }
                    }
                    var job = new Worker.Job(Worker.ExecutionType.ONCE, on_delete_finished);
                    db_worker.push_job(job);
                }
                s.destroy();
            });
            msg.run();
        }
        else if(item.type == ItemType.COLLECTION_CONTAINER_ARTIST) {
            var msg = new Gtk.MessageDialog(main_window, Gtk.DialogFlags.MODAL, Gtk.MessageType.QUESTION,
                                            Gtk.ButtonsType.OK_CANCEL,
                                            _("Do you want to delete the selected artist from the device?"));
            msg.response.connect( (s, response_id) => {
                //print("response id %d\n", response_id);
                if((Gtk.ResponseType)response_id == Gtk.ResponseType.OK) {
                    HashTable<ItemType,Item?>? items = new HashTable<ItemType,Item?>(direct_hash, direct_equal);
                    items.insert(item.type, item);
                    TrackData[] tda = 
                        audio_player_device.db.get_trackdata_for_artist(EMPTYSTRING,
                                                                        CollectionSortMode.ARTIST_ALBUM_TITLE,
                                                                        items);
                    foreach(TrackData td in tda) {
                        try {
                            File f = File.new_for_uri(td.item.uri);
                            f.delete(cancellable);
                            delete_from_database(td.item);
                        }
                        catch(GLib.Error e) {
                            print("%s\n", e.message);
                        }
                    }
                    var job = new Worker.Job(Worker.ExecutionType.ONCE, on_delete_finished);
                    db_worker.push_job(job);
                }
                s.destroy();
            });
            msg.run();
        }
    }
    
    private void delete_from_database(Item? item) {
        if(cancellable.is_cancelled())
            return;
        var job = new Worker.Job(Worker.ExecutionType.ONCE, this.delete_from_database_cb);
        job.item = item;
        db_worker.push_job(job);
    }
    
    private bool delete_from_database_cb(Worker.Job job) {
        if(cancellable.is_cancelled())
            return false;
        audio_player_device.db.remove_uri(job.item.uri);
        return false;
    }
    
    private bool on_delete_finished(Worker.Job job) {
        Idle.add(() => {
            audio_player_device.view.tree.treemodel.filter();
            return false;
        });
        return false;
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
        Gtk.TreeIter iter = Gtk.TreeIter();
        Item[] items = {};
        uint msg_id = 0;
        Idle.add( () => {
            msg_id = userinfo.popup(UserInfo.RemovalType.EXTERNAL,
                                    UserInfo.ContentClass.WAIT,
                                    _("Please wait while moving media to the device."),
                                    false,
                                    10,
                                    null);
            var job = new Worker.Job(Worker.ExecutionType.ONCE, prep_copy_files_job);
            foreach(Gtk.TreePath path in list) {
                mod.get_iter(out iter, path);
                mod.get(iter, tq.get_model_item_column(), out ix);
                items += ix;
            }
            job.items = items;
            job.set_arg("msg_id", msg_id);
            db_worker.push_job(job);
            
            return false;
        });
    }
    
    private bool prep_copy_files_job(Worker.Job _job) {
        var job = new Worker.Job(Worker.ExecutionType.ONCE, copy_files_job);
        uint msg_id = (uint)_job.get_arg("msg_id");
        job.track_dat = prepare_track_items(_job);
        job.set_arg("msg_id", msg_id);
        device_worker.push_job(job);
        return false;
    }
    
    private TrackData[] prepare_track_items(Worker.Job job) {
        TrackData[] ia = {};
        foreach(Item? i in job.items) {
            if(i.type == ItemType.LOCAL_AUDIO_TRACK ||
               i.type == ItemType.LOCAL_VIDEO_TRACK) {
                TrackData[] track_dat = item_converter.to_trackdata(i, global.searchtext, null);
                foreach(var td in track_dat) {
                    ia += td;
                }
                continue;
            }
            if(i.type == ItemType.COLLECTION_CONTAINER_ALBUM) {
                TrackData[] track_dat = item_converter.to_trackdata(i, global.searchtext, null);
                foreach(var td in track_dat) {
                    ia += td;
                }
                continue;
            }
            if(i.type == ItemType.COLLECTION_CONTAINER_ARTIST) {
                TrackData[] track_dat = item_converter.to_trackdata(i, global.searchtext, null);
                foreach(var td in track_dat) {
                    ia += td;
                }
                continue;
            }
        }
        return ia;
    }
    
    private bool copy_files_job(Worker.Job job) {
        if(cancellable.is_cancelled())
            return false;
        if(!(this.audio_player_device is IAudioPlayerDevice))
            return false;
        
        string[] destinations = {};
        
        File dest_base = File.new_for_uri(this.audio_player_device.get_uri());
        assert(dest_base != null);
        File dest1 = dest_base.get_child("Music");
        assert(dest1 != null);
        if(!dest1.query_exists(cancellable)) {
            dest1 = dest_base.get_child("media");
        }
        dest_base = dest1;
        foreach(TrackData td in job.track_dat) {
            
            File s = File.new_for_uri(td.item.uri);
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
                                        _("Not enough space on device! Aborting..."),
                                        false,
                                        10,
                                        null);
                break;
            }
            else {
                File dest = dest_base.get_child(s.get_basename());
                assert(dest != null);
                //print("dest : %s\n", dest.get_path());
                try {
                    s.copy(dest, FileCopyFlags.NONE, cancellable, null);
                }
                catch(Error e) {
                    print("%s\n", e.message);
                    continue;
                }
                destinations += dest.get_uri();
                //print("done copying file to android device.\n");
            }
        }
        
        Timeout.add(200, () => {
            if(cancellable.is_cancelled())
                return false;
            audio_player_device.sign_add_track(destinations);
            return false;
        });
        Timeout.add_seconds(1, () => {
            uint msg_id = (uint)job.get_arg("msg_id");
            if(msg_id != 0) {
                userinfo.popdown(msg_id);
            }
            return false;
        });
        return false;
    }
}

