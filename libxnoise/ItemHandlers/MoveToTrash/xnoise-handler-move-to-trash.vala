/* xnoise-handler-move-to-trash.vala
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


using Sqlite;

using Xnoise;
using Xnoise.Services;

// ItemHandler Implementation 
// provides the right Action for the given ActionContext/ItemType
internal class Xnoise.HandlerMoveToTrash : ItemHandler {
    private Action a;
    private const string ainfo = _("Move to trash");
    private const string aname = "A HandlerMoveToTrash";
    
    private const string name = "HandlerMoveToTrash";
    
    public HandlerMoveToTrash() {
        a = new Action();
        a.action = trash_item;
        a.info = this.ainfo;
        a.name = this.aname;
        a.stock_item = Gtk.Stock.DELETE;
        a.context = ActionContext.TRACKLIST_MENU_QUERY;
    }

    public override ItemHandlerType handler_type() {
        return ItemHandlerType.MENU_PROVIDER;
    }
    
    public override unowned string handler_name() {
        return name;
    }

    public override unowned Action? get_action(ItemType type,
                                               ActionContext context,
                                               ItemSelectionType selection = ItemSelectionType.NOT_SET) {
        if(selection != ItemSelectionType.SINGLE)
            return null;
        if((context == ActionContext.TRACKLIST_MENU_QUERY ||
            context == ActionContext.QUERYABLE_PLAYLIST_MENU_QUERY) &&
           (type == ItemType.LOCAL_AUDIO_TRACK || 
            type == ItemType.LOCAL_VIDEO_TRACK)) {
            
            return a;
        }
        
        return null;
    }
    
    private string? uri = null;
    
    private void trash_item(Item item, GLib.Value? data) { 
        if(item.type != ItemType.LOCAL_AUDIO_TRACK && item.type != ItemType.LOCAL_VIDEO_TRACK) 
            return;
        this.uri = item.uri;
        var msg = new Gtk.MessageDialog(main_window, Gtk.DialogFlags.MODAL, Gtk.MessageType.QUESTION,
                                        Gtk.ButtonsType.OK_CANCEL,
                                        _("Do you want to move the selected file to trash?"));
        msg.response.connect( (s, response_id) => {
            //print("response id %d\n", response_id);
            if((Gtk.ResponseType)response_id == Gtk.ResponseType.OK) {
                try {
                    tl.remove_uri_rows(item.uri);
                    File f = File.new_for_uri(item.uri);
                    f.trash(null);
                    delete_from_database();
                }
                catch(GLib.Error e) {
                    print("%s\n", e.message);
                }
            }
            s.destroy();
        });
        msg.run();
    }
    
    private void delete_from_database() {
        Worker.Job job = new Worker.Job(Worker.ExecutionType.ONCE, this.delete_from_database_cb);
        job.finished.connect(on_delete_finished);
        db_worker.push_job(job);
    }
    
    private bool delete_from_database_cb(Worker.Job job) {
        db_writer.remove_uri(this.uri);
        return false;
    }
    
    private void on_delete_finished(Worker.Job sender) {
        sender.finished.disconnect(on_delete_finished);
        string buf = global.searchtext;
        global.searchtext = Random.next_int().to_string();
        global.searchtext = buf;
    }
}

