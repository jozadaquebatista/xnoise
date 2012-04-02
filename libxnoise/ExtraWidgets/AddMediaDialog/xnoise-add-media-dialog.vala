/* xnoise-add-media-dialog.vala
 *
 * Copyright (C) 2009-2012  Jörn Magens
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
using Xnoise.Services;


public class Xnoise.AddMediaDialog : GLib.Object {

    private enum Column {
        NAME,
        ITEMTYPE,
        LOCATION,
        COL_COUNT
    }
    
    private const string XNOISEICON = Config.UIDIR + "xnoise_16x16.png";
    private Gtk.Dialog dialog;
    private ListStore listmodel;
    private TreeView tv;
    private CheckButton fullrescancheckb;
    private unowned Main xn;
    
    public Gtk.Builder builder;

    public signal void sign_finish();

    public AddMediaDialog() {
        xn = Main.instance;
        builder = new Gtk.Builder();
        create_widgets();
        
        fill_media_list();
        
        dialog.set_position(Gtk.WindowPosition.CENTER_ON_PARENT);
        dialog.show_all();
    }

    //    ~AddMediaDialog() {
    //        print("destruct amd\n");
    //    }

    private void fill_media_list() {
        return_if_fail(listmodel != null);
        
        Worker.Job job;
        job = new Worker.Job(Worker.ExecutionType.ONCE, fill_media_list_job);
        db_worker.push_job(job);
    }
    
    private bool fill_media_list_job(Worker.Job job) {
        //add folders
        Item[] mfolders = db_reader.get_media_folders();
        
        //add streams to list
        Item[] tmp = db_reader.get_stream_items("");
        Item[] streams = {};
        
        for(int j = tmp.length -1; j >= 0; j--) // reverse
            streams += tmp[j];
        
        Idle.add( () => {
            foreach(Item? i in mfolders) {
                File f = File.new_for_uri(i.uri);
                TreeIter iter;
                listmodel.append(out iter);
                listmodel.set(iter,
                              Column.LOCATION,  f.get_path(), // path
                              Column.ITEMTYPE,  i.type,
                              Column.NAME,      i.text        // name
                );
            }
            foreach(Item? i in streams) {
                TreeIter iter;
                listmodel.append(out iter);
                listmodel.set(iter,
                              Column.LOCATION,  i.uri, // uri
                              Column.ITEMTYPE,  i.type,
                              Column.NAME,      i.text // name
                );
            }
            return false;
        });
        return false;
    }

    private Item[] harvest_media_locations() {
        Item[] media_items = {};
        listmodel.foreach( (sender, mypath, myiter) => {
            string d_uri;
            string d_name;
            ItemType tp;
            sender.get(myiter,
                       Column.LOCATION, out d_uri,
                       Column.ITEMTYPE, out tp,
                       Column.NAME, out d_name
            );
            switch(tp) {
                case ItemType.LOCAL_FOLDER:
                    File f = File.new_for_path(d_uri);
                    Item? item = Item(ItemType.LOCAL_FOLDER, f.get_uri(), -1);
                    item.text = d_name; //TODO
                    media_items += item;
                    break;
                case ItemType.STREAM:
                case ItemType.PLAYLIST:
                    Item? item = Item(tp, d_uri, -1);
                    item.text = d_name; //TODO
                    media_items += item;
                    break;
                default:
                    print("Error: unhandled media storage type: %s\n", tp.to_string());
                    break;
            }
            return false;
        });
        return media_items;
    }

    private void create_widgets() {
        ScrolledWindow tvscrolledwindow = null;
        try {
            dialog = new Dialog();
            dialog.set_default_size(800, 600);
            dialog.set_modal(true);
            dialog.set_transient_for(main_window);
            
            builder.add_from_file(Config.UIDIR + "add_media.ui");
            
            var mainvbox           = builder.get_object("mainvbox") as Gtk.Box;
            tvscrolledwindow       = builder.get_object("tvscrolledwindow") as ScrolledWindow;
            var baddfolder         = builder.get_object("addfolderbutton") as Button;
            var baddradio          = builder.get_object("addradiobutton") as Button;
            var brem               = builder.get_object("removeButton") as Button;
            
            var labeladdfolder     = builder.get_object("labeladdfolder") as Label;
            var labeladdstream     = builder.get_object("labeladdstream") as Label;
            var labelremove        = builder.get_object("labelremove") as Label;
            var descriptionlabel   = builder.get_object("descriptionlabel") as Label;
            
            fullrescancheckb       = builder.get_object("fullrescancheckb") as CheckButton;
            var bcancel            = (Button)this.dialog.add_button(Gtk.Stock.CANCEL, 0);
            var bok                = (Button)this.dialog.add_button(Gtk.Stock.OK, 1);
            
            labeladdfolder.label   = _("Add local folder");
            labeladdstream.label   = _("Add media stream");
            labelremove.label      = _("Remove");
            fullrescancheckb.label = _("do full rescan");
            descriptionlabel.label = _("Select local media folders or internet media streams. \nAll media sources will be available via xnoise's library.");
            
            bok.clicked.connect(on_ok_button_clicked);
            bcancel.clicked.connect(on_cancel_button_clicked);
            baddfolder.clicked.connect(on_add_folder_button_clicked);
            baddradio.clicked.connect(on_add_radio_button_clicked);
            brem.clicked.connect(on_remove_button_clicked);
            
            ((Gtk.Box)this.dialog.get_content_area()).add(mainvbox);
            this.dialog.set_icon_from_file(XNOISEICON);
            this.dialog.set_title(_("xnoise - Add media sources to the library"));
        }
        catch (GLib.Error e) {
            var msg = new Gtk.MessageDialog(null,
                                            Gtk.DialogFlags.MODAL,
                                            Gtk.MessageType.ERROR,
                                            Gtk.ButtonsType.CANCEL,
                                            "Failed to build dialog! %s\n".printf(e.message));
            msg.run();
            return;
        }
        
        tv = new TreeView();
        listmodel = new ListStore(Column.COL_COUNT, typeof(string), typeof(ItemType), typeof(string));
        
        //NAME
        var column2 = new TreeViewColumn();
        var renderername = new CellRendererText();
        renderername.mode = CellRendererMode.EDITABLE;
        renderername.editable = true;
        renderername.editable_set = true;
        column2.pack_start(renderername, false);
        column2.add_attribute(renderername, "text", Column.NAME);
        column2.title = _("Name");
        tv.insert_column(column2, -1);
        renderername.edited.connect( (s,ps,t) => {
            TreePath p = new TreePath.from_string(ps);
            TreeIter iter;
            listmodel.get_iter(out iter, p);
            listmodel.set(iter,
                          Column.NAME, t
            );
        });
        
        // LOCATION
        var column = new TreeViewColumn();
        var renderer = new CellRendererText();
        column.pack_start(renderer, false);
        column.add_attribute(renderer, "text", Column.LOCATION);
        column.title = _("Location");
        tv.insert_column(column, -1);
        
        tvscrolledwindow.add(tv);
        tvscrolledwindow.set_vexpand(true);
        tvscrolledwindow.set_vexpand_set(true);
        
        tv.set_model(listmodel);
        //TODO add icons
    }

    private void on_ok_button_clicked() {
        bool interrupted_populate_model = false;
        if(main_window.mediaBr.mediabrowsermodel.populating_model) {
            interrupted_populate_model = true; // that means we have to complete filling of the model after import
            //print("was still populating model\n");
        }
        
        var prg_bar = new Gtk.ProgressBar();
        prg_bar.set_fraction(0.0);
        prg_bar.set_text("0 / 0");
        
        Timeout.add(200, () => {
            uint msg_id = userinfo.popup(UserInfo.RemovalType.EXTERNAL,
                                UserInfo.ContentClass.WAIT,
                                _("Importing media data. This may take some time..."),
                                true,
                                5,
                                prg_bar);
            
            Item[] media_items = harvest_media_locations();
            
            global.media_import_in_progress = true;
            
            media_importer.import_media_groups(media_items, msg_id, fullrescancheckb.get_active(), interrupted_populate_model);
            
            this.dialog.destroy();
            this.sign_finish();
            return false;
        });
    }

    private void on_cancel_button_clicked() {
        this.dialog.destroy();
        this.sign_finish();
    }

    private void on_add_folder_button_clicked() {
        Gtk.FileChooserDialog fcdialog = new Gtk.FileChooserDialog(
            _("Select media folder"),
            this.dialog,
            Gtk.FileChooserAction.SELECT_FOLDER,
            Gtk.Stock.CANCEL,
            Gtk.ResponseType.CANCEL,
            Gtk.Stock.OPEN,
            Gtk.ResponseType.ACCEPT,
            null);
        fcdialog.set_current_folder(Environment.get_home_dir());
        if (fcdialog.run() == Gtk.ResponseType.ACCEPT) {
            File f = File.new_for_path(fcdialog.get_filename());
            TreeIter iter;
            listmodel.append(out iter);
            listmodel.set(iter,
                          Column.LOCATION,  f.get_path(),
                          Column.ITEMTYPE,  ItemType.LOCAL_FOLDER,
                          Column.NAME,      f.get_basename()
                          );
        }
        fcdialog.destroy();
        fcdialog = null;
    }


    private Gtk.Dialog radiodialog;
    private Gtk.Entry radioentry;

    private void on_add_radio_button_clicked() {
        radiodialog = new Gtk.Dialog();
        radiodialog.set_modal(true);
        radiodialog.set_transient_for(dialog);
        
        radioentry = new Gtk.Entry();
        radioentry.set_width_chars(50);
        radioentry.secondary_icon_stock = Gtk.Stock.CLEAR;
        radioentry.set_icon_activatable(Gtk.EntryIconPosition.SECONDARY, true);
        radioentry.icon_press.connect( (s, p0, p1) => { // s:Entry, p0:Position, p1:Gdk.Event
            if(p0 == Gtk.EntryIconPosition.SECONDARY) s.text = EMPTYSTRING;
        });
        ((Gtk.Box)radiodialog.get_content_area()).pack_start(radioentry, true, true, 0);
        
        var radiocancelbutton = (Gtk.Button)radiodialog.add_button(Gtk.Stock.CANCEL, 0);
        radiocancelbutton.clicked.connect( () => {
            radiodialog.close();
            radiodialog = null;
        });
        
        var radiookbutton = (Gtk.Button)radiodialog.add_button(Gtk.Stock.OK, 1);
        radiookbutton.clicked.connect( () => {
            if((radioentry.text!=null)&&
               (radioentry.text.strip() != EMPTYSTRING)) {
                TreeIter iter;
                listmodel.append(out iter);
                listmodel.set(iter,
                              Column.LOCATION,  radioentry.text.strip(),
                              Column.ITEMTYPE,  ItemType.STREAM,
                              Column.NAME,      radioentry.text.strip()
                              );
            }
            radiodialog.close();
            radiodialog = null;
        });
        
        radiodialog.destroy_event.connect( () => {
            radiodialog = null;
            return true;
        });
        try {
            radiodialog.set_icon_from_file(XNOISEICON);
            radiodialog.set_title(_("Add internet radio link"));
        }
        catch(GLib.Error e) {
            var msg = new Gtk.MessageDialog(null,
                                            Gtk.DialogFlags.MODAL,
                                            Gtk.MessageType.ERROR,
                                            Gtk.ButtonsType.CANCEL,
                                            "Failed set icon! %s\n".printf(e.message)
                                            );
            msg.run();
        }
        radiodialog.set_position(Gtk.WindowPosition.CENTER_ON_PARENT);
        radiodialog.show_all();
    }

    // Removes entry from the media library
    private void on_remove_button_clicked() {
        Gtk.TreeSelection selection = tv.get_selection ();
        if(selection.count_selected_rows() > 0) {
            TreeIter iter;
            selection.get_selected(null, out iter);
            listmodel.remove(iter);
        }
    }
}

