/* xnoise-tag-artist-editor.vala
 *
 * Copyright (C) 2011 - 2013  Jörn Magens
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

using Gtk;

using Xnoise;
using Xnoise.Resources;
using Xnoise.TagAccess;


private class Xnoise.TagArtistEditor : GLib.Object {
    private unowned Xnoise.Main xn;
    private Dialog dialog;
    private Gtk.Builder builder;
    private string new_content_name = null;
    private unowned MusicBrowserModel mbm = null;
    
    private Entry entry;
    
    
    private Item? item;
    private HashTable<ItemType,Item?>? restrictions;
    public signal void sign_finish();

    public TagArtistEditor(Item _item, HashTable<ItemType,Item?>? restrictions = null) {
        this.item = _item;
        this.restrictions = restrictions;
        xn = Main.instance;
        td_old = {};
        builder = new Gtk.Builder();
        setup_widgets();
        mbm = main_window.musicBr.music_browser_model;
        mbm.notify["populating-model"].connect( () => {
            if(!global.media_import_in_progress && !mbm.populating_model)
                infolabel.label = _("With this dialog you can change the metatags in the according files. \nHandle with care!");
        });
        global.notify["media-import-in-progress"].connect( () => {
            if(!global.media_import_in_progress && !mbm.populating_model)
                infolabel.label = _("With this dialog you can change the metatags in the according files. \nHandle with care!");
        });
        
        fill_entries();
        dialog.set_position(Gtk.WindowPosition.CENTER_ON_PARENT);
        dialog.show_all();
    }
    
    private void fill_entries() {
        Worker.Job job;
        job = new Worker.Job(Worker.ExecutionType.ONCE, this.query_trackdata_job, Worker.Priority.HIGH);
        job.item = item;
        db_worker.push_job(job);
    }

    private TrackData[] td_old;
    
    private bool query_trackdata_job(Worker.Job job) {
        // callback for query in other thread
        //print("this.item.type:%s\n", this.item.type.to_string());
        td_old = item_converter.to_trackdata(this.item, global.searchtext, restrictions);
        assert(td_old[0] != null);
        TrackData? td = td_old[0];
        switch(item.type) {
            case ItemType.COLLECTION_CONTAINER_ARTIST:
                Idle.add( () => {
                    // put data to entry
                    entry.text  = td.artist;
                    return false;
                });
                break;
            default:
                Idle.add( () => {
                    sign_finish();
                    return false;
                });
                break;
        }
        return false;
    }

    private Label infolabel;
    private void setup_widgets() {
        try {
            dialog = new Dialog();
            
            dialog.set_modal(true);
            dialog.set_transient_for(main_window);
            
            builder.add_from_file(Config.XN_UIDIR + "metadat_artist_album.ui");
            
            var mainvbox           = builder.get_object("vbox1")           as Gtk.Box;
            var okbutton           = builder.get_object("okbutton")        as Gtk.Button;
            var cancelbutton       = builder.get_object("cancelbutton")    as Gtk.Button;
            entry                  = builder.get_object("entry1")          as Gtk.Entry;
            infolabel              = builder.get_object("label5")          as Gtk.Label;
            infolabel.label = _("With this dialog you can change the metatags in the according files. \nHandle with care!");;
            var explainer_label    = builder.get_object("explainer_label") as Gtk.Label;
            var content_label      = builder.get_object("content_label")   as Gtk.Label;
            
            ((Gtk.Box)this.dialog.get_content_area()).add(mainvbox);
            okbutton.clicked.connect(on_ok_button_clicked);
            cancelbutton.clicked.connect(on_cancel_button_clicked);
            
            this.dialog.set_title(_("xnoise - Edit metadata"));
            switch(item.type) {
                case ItemType.COLLECTION_CONTAINER_ARTIST:
                    explainer_label.label = _("Type new artist name.");
                    content_label.label = _("Artist:");
                    break;
//                case ItemType.COLLECTION_CONTAINER_ALBUM:
//                    explainer_label.label = _("Type new album name.");
//                    content_label.label = _("Album:");
//                    break;
                default:
                    break;    
            }
        }
        catch (GLib.Error e) {
            var msg = new Gtk.MessageDialog(null,
                                            Gtk.DialogFlags.MODAL,
                                            Gtk.MessageType.ERROR,
                                            Gtk.ButtonsType.CANCEL,
                                            "Failed to build dialog! %s\n",
                                            e.message);
            msg.run();
            return;
        }
    }
    
    private void on_ok_button_clicked(Gtk.Button sender) {
        if(mbm.populating_model) {
            infolabel.label = _("Please wait while filling media browser. Or cancel, if you do not want to wait.");
            return;
        }
        if(global.media_import_in_progress) {
            infolabel.label = _("Please wait while importing media. Or cancel, if you do not want to wait.");
            return;
        }
        infolabel.label = EMPTYSTRING;
        if(entry.text != null && entry.text.strip() != EMPTYSTRING)
            new_content_name = entry.text.strip();
        // TODO: UTF-8 validation
        switch(item.type) {
            case ItemType.COLLECTION_CONTAINER_ARTIST:
                do_artist_rename();
                break;
//            case ItemType.COLLECTION_CONTAINER_ALBUM:
//                do_album_rename();
//                break;
            default:
                break;    
        }
        Idle.add( () => {
            this.dialog.destroy();
            return false;
        });
    }
    
    private void do_artist_rename() {
        var job = new Worker.Job(Worker.ExecutionType.ONCE, this.update_tags_job);
        job.set_arg("new_content_name", new_content_name);
        job.item = this.item;
        db_worker.push_job(job);
    }

//    private void do_album_rename() {
//        var job = new Worker.Job(Worker.ExecutionType.ONCE, this.update_tags_job);
//        job.set_arg("new_content_name", new_content_name);
//        job.item = this.item;
//        io_worker.push_job(job);
//    }


    private bool update_tags_job(Worker.Job tag_job) {
        assert(tag_job.item.type == ItemType.COLLECTION_CONTAINER_ARTIST);
        var job = new Worker.Job(Worker.ExecutionType.ONCE, this.update_filetags_job);
        //print("%s %d\n", tag_job.item.type.to_string(), tag_job.item.db_id);
        job.track_dat = td_old; //item_converter.to_trackdata(tag_job.item, global.searchtext);
        if(job.track_dat == null)
            return false;
        job.item = tag_job.item;
        foreach(TrackData td in job.track_dat) {
            td.artist = new_content_name;
        }
        print("push filetags job\n");
        global.in_tag_rename = true;
        io_worker.push_job(job);
        return false;
    }

    private bool update_filetags_job(Worker.Job job) {
        string[] uris = {};
        for(int i = 0; i < job.track_dat.length; i++) {
            File f = File.new_for_uri(job.track_dat[i].item.uri);
            if(!f.query_exists(null))
                continue;
            bool ret = false;
            var tw = new TagWriter();
            ret = tw.write_tag(f, job.track_dat[i], false);
            
            if(ret) {
                uris += f.get_uri();
            }
            else {
                print("No success for path : %s !!!\n", f.get_path());
            }
        }
        media_importer.reimport_media_files(uris);
        
        var fin_job = new Worker.Job(Worker.ExecutionType.ONCE, this.finish_job);
        
        db_worker.push_job(fin_job);
        return false;
    }
    
    private bool finish_job(Worker.Job job) {
//        db_writer.commit_transaction();
        Timeout.add(200, () => {
            main_window.musicBr.music_browser_model.filter();
            main_window.album_art_view.icons_model.filter();
            global.in_tag_rename = false;
            return false;
        });
        Timeout.add(300, () => {
            this.sign_finish();
            return false;
        });
        return false;
    }

    private void on_cancel_button_clicked(Gtk.Button sender) {
        Idle.add( () => {
            this.dialog.destroy();
            this.sign_finish();
            return false;
        });
    }
}


