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
        VIZ_TEXT,
        ITEM,
//        STATUS,
//        ACTIVITY,
        COL_COUNT
    }
    
    private const string XNOISEICON = "xnoise";
    private ListStore listmodel;
    private TreeView tv;
    
    public Gtk.Builder builder;

    public AddMediaWidget() {
        GLib.Object(orientation:Orientation.VERTICAL, spacing:0);
        builder = new Gtk.Builder();
        setup_widgets();
        this.show_all();
    }

    private void setup_widgets() {
        Gtk.Box devbox;
        try {
            builder.add_from_file(Config.XN_UIDIR + "add_media.ui");
            
            var headline           = builder.get_object("addremove_headline") as Label;
            headline.set_alignment(0.0f, 0.5f);
            headline.use_markup= true;
            headline.set_markup("<span size=\"xx-large\"><b> %s </b></span>".printf(Markup.escape_text(_("Manage media folders"))));

            var scrolledwindow1           = builder.get_object("scrolledwindow1") as Gtk.ScrolledWindow;
            devbox             = builder.get_object("box_devices") as Gtk.Box;
//            tvscrolledwindow       = builder.get_object("tvscrolledwindow") as ScrolledWindow;
            var baddfolder         = builder.get_object("addfolderbutton") as ToolButton;
//            var baddradio          = builder.get_object("streambutton") as ToolButton;
            var brem               = builder.get_object("removebutton") as ToolButton;
            var descriptionlabel   = builder.get_object("descriptionlabel") as Label;
            
            baddfolder.tooltip_text = _("Add local folder");
//            baddradio.tooltip_text  = _("Add media stream");
            brem.tooltip_text       = _("Remove");
            
            descriptionlabel.set_line_wrap(true);
            descriptionlabel.set_line_wrap_mode(Pango.WrapMode.WORD);
            descriptionlabel.label = 
                _("Select local media folders. \nAll found media files will be available via xnoise's library.");
            descriptionlabel.set_line_wrap(true);
            descriptionlabel.set_line_wrap_mode(Pango.WrapMode.WORD);
            this.pack_start(scrolledwindow1, true, true, 0);
            
            baddfolder.clicked.connect(on_add_folder_button_clicked);
//            baddradio.clicked.connect(on_add_radio_button_clicked);
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
        tv.get_selection().set_mode(SelectionMode.MULTIPLE);
        
        listmodel = new ListStore(Column.COL_COUNT, 
                                  typeof(Gdk.Pixbuf), 
                                  typeof(string), 
                                  typeof(Item?), 
                                  typeof(int),
                                  typeof(int));
        
        //ICON
        var column = new TreeViewColumn();
        var rendererpb = new CellRendererPixbuf();
        column.pack_start(rendererpb, false);
        column.add_attribute(rendererpb, "pixbuf", Column.ICON);
        tv.insert_column(column, -1);
        
        // VIZ_TEXT
        column = new TreeViewColumn();
        var renderer = new CellRendererText();
        column.pack_start(renderer, true);
        column.add_attribute(renderer, "text", Column.VIZ_TEXT);
        column.title = _("Location");
        tv.insert_column(column, -1);
        
//        // STATUS
//        column = new TreeViewColumn();
//        var rendererspinner = new CellRendererSpinner();
//        column.pack_start(rendererspinner, false);
//        column.add_attribute(rendererspinner, "active", Column.STATUS);
//        column.add_attribute(rendererspinner, "pulse", Column.ACTIVITY);
//        tv.insert_column(column, -1);
        
        devbox.pack_start(tv, true, true, 0);
        
        tv.set_model(listmodel);
        tv.show_all();
        
        media_importer.folder_list_changed.connect( () => {
            update_item_list();
        });
//        media_importer.stream_list_changed.connect( () => {
//            update_item_list();
//        });
        Idle.add(() => {
            update_item_list();
            return false;
        });
        media_importer.media_folder_state_change.connect( (s) => {
            update_item_list();
        });
//        media_importer.processing_import_target.connect( (s,i) => {
//            listmodel.foreach( (sender, mypath, myiter) => {
//                Item? item;
//                int activity;
//                listmodel.get(myiter, Column.ITEM, out item);
//                if(i.uri == item.uri) {
//                    
//                    uint xx = Timeout.add(250, () => {
//                        bool stopped = false;
//                        bool found = false;
//                        listmodel.foreach( (sx, px, itx) => {
//                            Item? itemx;
//                            listmodel.get(itx, Column.ITEM, out itemx);
//                            if(i.uri == itemx.uri) {
//                                found = true;
//                                int stat = 0;
//                                int act;
//                                listmodel.get(itx, 
//                                              Column.ACTIVITY, out act,
//                                              Column.STATUS,   out stat);
//                                if(act > 0) {
//                                    act++;
//                                    listmodel.set(itx, Column.ACTIVITY, act);
//                                }
//                                else {
//                                    stopped = true;
//                                }
//                                return true;
//                            }
//                            return false;
//                        });
//                        if(stopped || !found)
//                            return false;
//                        return true;
//                    });
//                    return true;
//                }
//                return false;
//            });
//        });
    }
    
    private void update_item_list() {
        Gtk.Invisible w = new Gtk.Invisible();
        Gdk.Pixbuf folder_icon = w.render_icon_pixbuf(Gtk.STOCK_DIRECTORY, IconSize.MENU);
        listmodel.clear();
        GLib.List<Item?> list = media_importer.get_media_folder_list();
        foreach(Item? i in list) {
            File f = File.new_for_uri(i.uri);
            TreeIter iter;
            listmodel.append(out iter);
            listmodel.set(iter,
                          Column.ICON,      folder_icon,
                          Column.VIZ_TEXT,  f.get_path(),
                          Column.ITEM, i
            );
        }
//        list = media_importer.get_media_streams_list();
//        foreach(Item? i in list) {
//            File f = File.new_for_uri(i.uri);
//            TreeIter iter;
//            listmodel.append(out iter);
//            listmodel.set(iter,
//                          Column.ICON,      folder_icon,
//                          Column.VIZ_TEXT,  i.text,
//                          Column.ITEM, i
//            );
//        }
        print("updated list\n");
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
            foreach(string fn in fcdialog.get_filenames()) {
                File f = File.new_for_path(fn);
                Item item = Item(ItemType.LOCAL_FOLDER, f.get_uri());
                media_importer.add_import_target_folder(item, true);
            }
        }
        fcdialog.destroy();
        fcdialog = null;
    }


//    private Gtk.Dialog radiodialog;
//    private Gtk.Entry radioentry;

//    private void on_add_radio_button_clicked() {
//        radiodialog = new Gtk.Dialog();
//        radiodialog.set_modal(true);
//        radiodialog.set_transient_for(main_window);
//        
//        radioentry = new Gtk.Entry();
//        radioentry.set_width_chars(50);
//        radioentry.secondary_icon_stock = Gtk.Stock.CLEAR;
//        radioentry.set_icon_activatable(Gtk.EntryIconPosition.SECONDARY, true);
//        radioentry.icon_press.connect( (s, p0, p1) => { // s:Entry, p0:Position, p1:Gdk.Event
//            if(p0 == Gtk.EntryIconPosition.SECONDARY) s.text = EMPTYSTRING;
//        });
//        ((Gtk.Box)radiodialog.get_content_area()).pack_start(radioentry, true, true, 0);
//        
//        var radiocancelbutton = (Gtk.Button)radiodialog.add_button(Gtk.Stock.CANCEL, 0);
//        radiocancelbutton.clicked.connect( () => {
//            radiodialog.close();
//            radiodialog = null;
//        });
//        
//        var radiookbutton = (Gtk.Button)radiodialog.add_button(Gtk.Stock.OK, 1);
//        radiookbutton.clicked.connect( () => {
//            if((radioentry.text!=null)&&
//               (radioentry.text.strip() != EMPTYSTRING)) {
//                Item? i = Item(ItemType.STREAM, radioentry.text.strip());
////                media_importer.add_...(i);
//            }
//            radiodialog.close();
//            radiodialog = null;
//        });
//        
//        radiodialog.destroy_event.connect( () => {
//            radiodialog = null;
//            return true;
//        });
//        radiodialog.set_icon_name(XNOISEICON);
//        radiodialog.set_title(_("Add internet radio link"));
//        radiodialog.set_position(Gtk.WindowPosition.CENTER_ON_PARENT);
//        radiodialog.show_all();
//    }

    // Removes entry from the media library
    private void on_remove_button_clicked() {
        Gtk.TreeSelection selection = tv.get_selection ();
        if(selection.count_selected_rows() > 0) {
            Gtk.TreeModel m;
            GLib.List<TreePath> selected_rows = selection.get_selected_rows(out m);
            foreach(TreePath tp in selected_rows) {
                TreeIter iter;
                listmodel.get_iter(out iter, tp);
                string? p = null;
                Item? i;
                listmodel.get(iter, 
                              Column.VIZ_TEXT, out p,
                              Column.ITEM,  out i);
                              
                if(i.type == ItemType.LOCAL_FOLDER && p != null)
                    media_importer.remove_media_folder(i);
            }
        }
    }
}

