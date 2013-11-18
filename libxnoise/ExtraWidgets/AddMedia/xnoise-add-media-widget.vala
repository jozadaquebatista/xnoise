/* xnoise-add-media-widget.vala
 *
 * Copyright (C) 2009-2013  Jörn Magens
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



private class Xnoise.AddMediaWidget : Gtk.Box {

    private enum Column {
        ICON,
        ITEMTYPE,
        LOCATION,
        COL_COUNT
    }
    
    private const string XNOISEICON = "xnoise";
    private ListStore listmodel;
    private TreeView tv;
    private Button bok;
    private bool fullrescan;
    private unowned Main xn;
    
    public Gtk.Builder builder;

    public AddMediaWidget() {
        GLib.Object(orientation:Orientation.VERTICAL, spacing:0);
        xn = Main.instance;
        builder = new Gtk.Builder();
        setup_widgets();
        
//        fill_media_list();
        
        this.show_all();
    }

    internal void update() {
//        fill_media_list();
    }
    
//    private void fill_media_list() {
//        return_if_fail(listmodel != null);
//        listmodel.clear();
//        Worker.Job job;
//        job = new Worker.Job(Worker.ExecutionType.ONCE, fill_media_list_job);
//        db_worker.push_job(job);
//    }
//    
//    private bool fill_media_list_job(Worker.Job job) {
        //add folders
//        GLib.List<Item?> mfolders = media_importer.get_media_folder_list();
//        
//        //add streams to list
//        Item[] tmp = db_reader.get_stream_items("");
//        Item[] streams = {};
//        
//        for(int j = tmp.length -1; j >= 0; j--) // reverse
//            streams += tmp[j];
//        
//        
//        Idle.add( () => {
//            Gtk.Invisible w = new Gtk.Invisible();
//            Gdk.Pixbuf folder_icon = w.render_icon_pixbuf(Gtk.Stock.DIRECTORY, IconSize.MENU);
//            foreach(Item? i in media_importer.get_media_folder_list()) {
//                File f = File.new_for_uri(i.uri);
//                TreeIter iter;
//                listmodel.append(out iter);
//                listmodel.set(iter,
//                              Column.ICON,      folder_icon,
//                              Column.LOCATION,  f.get_path(),
//                              Column.ITEMTYPE,  i.type
//                );
//            }
//            foreach(Item? i in streams) {
//                TreeIter iter;
//                listmodel.append(out iter);
//                listmodel.set(iter,
//                              Column.ICON,      icon_repo.radios_icon_menu,
//                              Column.LOCATION,  i.uri,
//                              Column.ITEMTYPE,  i.type
//                );
//            }
//            return false;
//        });
//        return false;
//    }

//    private Item[] harvest_media_locations() {
//        Item[] media_items = {};
//        listmodel.foreach( (sender, mypath, myiter) => {
//            string d_uri;
//            ItemType tp;
//            sender.get(myiter,
//                       Column.LOCATION, out d_uri,
//                       Column.ITEMTYPE, out tp//,
//            );
//            switch(tp) {
//                case ItemType.LOCAL_FOLDER:
//                    File f = File.new_for_path(d_uri);
//                    Item? item = Item(ItemType.LOCAL_FOLDER, f.get_uri(), -1);
//                    media_items += item;
//                    break;
//                case ItemType.STREAM:
//                case ItemType.PLAYLIST:
//                    Item? item = Item(tp, d_uri, -1);
//                    media_items += item;
//                    break;
//                default:
//                    print("Error: unhandled media storage type: %s\n", ((int)tp).to_string());
//                    break;
//            }
//            return false;
//        });
//        return media_items;
//    }

    private void setup_widgets() {
//        ScrolledWindow tvscrolledwindow = null;
        Gtk.Box devbox;
        try {
            builder.add_from_file(Config.XN_UIDIR + "add_media.ui");
            
            var headline           = builder.get_object("addremove_headline") as Label;
            headline.set_alignment(0.0f, 0.5f);
            headline.use_markup= true;
            headline.set_markup("<span size=\"xx-large\"><b> %s </b></span>".printf(Markup.escape_text(_("Add or Remove media"))));

            var scrolledwindow1           = builder.get_object("scrolledwindow1") as Gtk.ScrolledWindow;
            devbox             = builder.get_object("box_devices") as Gtk.Box;
//            tvscrolledwindow       = builder.get_object("tvscrolledwindow") as ScrolledWindow;
            var baddfolder         = builder.get_object("addfolderbutton") as ToolButton;
            var baddradio          = builder.get_object("streambutton") as ToolButton;
            var brem               = builder.get_object("removebutton") as ToolButton;
            var descriptionlabel   = builder.get_object("descriptionlabel") as Label;
            bok                    = builder.get_object("okbutton") as Button;
            bok.sensitive          = !global.media_import_in_progress;
            
            var fullrescan_check  = builder.get_object("fullrescan_check") as Gtk.CheckButton;
            fullrescan_check.label = _("Do full rescan");
            fullrescan_check.tooltip_text = _("If selected, all media folders will be fully rescanned");
            this.fullrescan = fullrescan_check.active = true;
            fullrescan_check.toggled.connect( () => {
                //print("active toggled. New val = %s\n", ((Switch)s).active.to_string());
                this.fullrescan = fullrescan_check.active;
            });
            
            baddfolder.tooltip_text = _("Add local folder");
            baddradio.tooltip_text  = _("Add media stream");
            brem.tooltip_text       = _("Remove");
            
            descriptionlabel.set_line_wrap(true);
            descriptionlabel.set_line_wrap_mode(Pango.WrapMode.WORD);
            descriptionlabel.label = _("Select local media folders or internet media streams. \nAll media sources will be available via xnoise's library.");
            descriptionlabel.set_line_wrap(true);
            descriptionlabel.set_line_wrap_mode(Pango.WrapMode.WORD);
            this.pack_start(scrolledwindow1, true, true, 0);
            
            bok.clicked.connect(on_ok_button_clicked);
            
            baddfolder.clicked.connect(on_add_folder_button_clicked);
            baddradio.clicked.connect(on_add_radio_button_clicked);
            brem.clicked.connect(on_remove_button_clicked);
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
        
        tv = new TreeView();
        tv.headers_visible = false;
        listmodel = new ListStore(Column.COL_COUNT, 
                                  typeof(Gdk.Pixbuf), 
                                  typeof(ItemType), 
                                  typeof(string));
        
        //NAME
        var column = new TreeViewColumn();
        var rendererpb = new CellRendererPixbuf();
        column.pack_start(rendererpb, false);
        column.add_attribute(rendererpb, "pixbuf", Column.ICON);
        tv.insert_column(column, -1);
        
        // LOCATION
        column = new TreeViewColumn();
        var renderer = new CellRendererText();
        column.pack_start(renderer, false);
        column.add_attribute(renderer, "text", Column.LOCATION);
        column.title = _("Location");
        tv.insert_column(column, -1);
        
        devbox.pack_start(tv, true, true, 0);
        
        tv.set_model(listmodel);
        tv.show();
        
        media_importer.folder_list_changed.connect( () => {
            update_item_list();
        });
        Idle.add(() => {
            update_item_list();
            return false;
        });
        global.notify["media-import-in-progress"].connect( () => {
            if(!global.media_import_in_progress) {
                this.update();
                bok.sensitive = true;
            }
            else {
                bok.sensitive = false;
            }
        });
    }
    
    private void update_item_list() {
        Gtk.Invisible w = new Gtk.Invisible();
        Gdk.Pixbuf folder_icon = w.render_icon_pixbuf(Gtk.Stock.DIRECTORY, IconSize.MENU);
        listmodel.clear();
        GLib.List<Item?> list = media_importer.get_media_folder_list();
        foreach(Item? i in list) {
            File f = File.new_for_uri(i.uri);
            TreeIter iter;
            listmodel.append(out iter);
            listmodel.set(iter,
                          Column.ICON,      folder_icon,
                          Column.LOCATION,  f.get_path(),
                          Column.ITEMTYPE,  ItemType.LOCAL_FOLDER
            );
        }
    }

    private void on_ok_button_clicked(Gtk.Button sender) {
        main_window.show_content();
//        bool interrupted_populate_model = false;
//        if(main_window.musicBr.music_browser_model.populating_model) {
//            interrupted_populate_model = true; 
//            // that means we have to complete filling of the model after import
//            //print("was still populating model\n");
//        }
//        var prg_bar = new Gtk.ProgressBar();
//        prg_bar.set_fraction(0.0);
//        prg_bar.set_text("0 / 0");
//        
//        Idle.add(() => {
//            main_window.show_content();
//            return false;
//        });
//        
//        Timeout.add(200, () => {
//            uint msg_id = userinfo.popup(UserInfo.RemovalType.EXTERNAL,
//                                UserInfo.ContentClass.WAIT,
//                                _("Importing media data. This may take some time..."),
//                                true,
//                                5,
//                                prg_bar);
//            Item[] media_items = harvest_media_locations();
//            global.media_import_in_progress = true;
//            media_importer.import_media_groups(media_items,
//                                               msg_id,
//                                               fullrescan,
//                                               interrupted_populate_model);
//            return false;
//        });
    }

    private void on_add_folder_button_clicked() {
        Gtk.FileChooserDialog fcdialog = new Gtk.FileChooserDialog(
            _("Select media folder"),
            main_window,
            Gtk.FileChooserAction.SELECT_FOLDER,
            Gtk.Stock.CANCEL,
            Gtk.ResponseType.CANCEL,
            Gtk.Stock.OPEN,
            Gtk.ResponseType.ACCEPT,
            null);
        fcdialog.select_multiple = true;
        fcdialog.set_current_folder(Environment.get_home_dir());
        string music = Environment.get_user_special_dir(UserDirectory.MUSIC);
        if(music != null && music != "")
            fcdialog.select_filename(music);
        if(fcdialog.run() == Gtk.ResponseType.ACCEPT) {
//            Gtk.Invisible w = new Gtk.Invisible();
//            Gdk.Pixbuf folder_icon = w.render_icon_pixbuf(Gtk.Stock.DIRECTORY, IconSize.MENU);
//            foreach(string fn in fcdialog.get_filenames()) {
//                File f = File.new_for_path(fn);
//                TreeIter iter;
//                listmodel.append(out iter);
//                listmodel.set(iter,
//                              Column.ICON,      folder_icon,
//                              Column.LOCATION,  f.get_path(),
//                              Column.ITEMTYPE,  ItemType.LOCAL_FOLDER
//                );
                File f = File.new_for_uri(fcdialog.get_uri());
                Item item = Item(ItemType.LOCAL_FOLDER, f.get_uri());
                var import_target = new ImportTarget();
                import_target.item = item;
                media_importer.add_import_target_folder(import_target);
//            }
        }
        fcdialog.destroy();
        fcdialog = null;
    }


    private Gtk.Dialog radiodialog;
    private Gtk.Entry radioentry;

    private void on_add_radio_button_clicked() {
        radiodialog = new Gtk.Dialog();
        radiodialog.set_modal(true);
        radiodialog.set_transient_for(main_window);
        
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
                              Column.ICON,      icon_repo.radios_icon_menu,
                              Column.LOCATION,  radioentry.text.strip(),
                              Column.ITEMTYPE,  ItemType.STREAM//,
                              );
            }
            radiodialog.close();
            radiodialog = null;
        });
        
        radiodialog.destroy_event.connect( () => {
            radiodialog = null;
            return true;
        });
        radiodialog.set_icon_name(XNOISEICON);
        radiodialog.set_title(_("Add internet radio link"));
        radiodialog.set_position(Gtk.WindowPosition.CENTER_ON_PARENT);
        radiodialog.show_all();
    }

    // Removes entry from the media library
    private void on_remove_button_clicked() {
        Gtk.TreeSelection selection = tv.get_selection ();
        if(selection.count_selected_rows() > 0) {
            TreeIter iter;
            selection.get_selected(null, out iter);
            string? p = null;
            ItemType t;
            listmodel.get(iter, 
                          Column.LOCATION, out p,
                          Column.ITEMTYPE,  out t);
                          
            if(t != ItemType.LOCAL_FOLDER || p == null)
                return;
            media_importer.remove_media_folder(p);
        }
    }
}

