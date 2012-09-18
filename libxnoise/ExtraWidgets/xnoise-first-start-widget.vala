/* xnoise-first-start-widget.vala
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

using Gtk;

using Xnoise;


private class Xnoise.FirstStartWidget : Box, IMainView {
    private const string WELCOME_UI_FILE = Config.UIDIR + "first_start.ui";
    private CssProvider provider;

    private enum Column {
        ICON,
        LOCATION,
        COL_COUNT
    }
    
    public Button closebutton;
    public Button finish_button;
    
    private Button addmore_button;
    private Spinner spinner;
    private Label import_label;
    private Box imported_box;
    private Box top_box;
    private Notebook nb;
    private Button button_add_folder;
    
    public FirstStartWidget(){
        create_widgets();
        this.show_all();
    }
    
    ~FirstStartWidget() {
        print("dtor first start widget\n");
    }
    
    public string get_view_name() {
        return "FirstStartWidget";
    }
    
    private HashTable<string,string> ht = new HashTable<string,string>(str_hash, str_equal);
    
    private void on_button_add_folder_clicked() {
        Gtk.FileChooserDialog fcdialog = new Gtk.FileChooserDialog(
            _("Select media folder"),
            main_window,
            Gtk.FileChooserAction.SELECT_FOLDER,
            Gtk.Stock.CANCEL,
            Gtk.ResponseType.CANCEL,
            Gtk.Stock.OPEN,
            Gtk.ResponseType.ACCEPT);
        fcdialog.set_current_folder(Environment.get_home_dir());
        if (fcdialog.run() == Gtk.ResponseType.ACCEPT) {
            File f = File.new_for_path(fcdialog.get_filename());
            TreeIter iter;
            if(ht.lookup(f.get_path()) == null) {
                ht.insert(f.get_path(),f.get_path());
                listmodel.append(out iter);
                listmodel.set(iter,
                              Column.ICON, icon_repo.selected_collection_icon,
                              Column.LOCATION,  f.get_path()
                              );
                media_importer.import_media_folder(f.get_path(), false, true);
                nb.set_current_page(1);
            }
        }
        fcdialog.destroy();
        fcdialog = null;
    }
    
    private TreeView tv;
    private ListStore listmodel;
    private Box infobox;
    private Box waitbox;
    private Box bigbox;
    
    private void create_widgets() {
        try {
            Builder gb = new Gtk.Builder();
            gb.add_from_file(WELCOME_UI_FILE);
            
            top_box = gb.get_object("topbox") as Gtk.Box;
            button_add_folder = gb.get_object("button_add_folder") as Button;
            button_add_folder.clicked.connect(on_button_add_folder_clicked);
            closebutton = gb.get_object("button2") as Gtk.Button;
            infobox = gb.get_object("infobox") as Gtk.Box;
            bigbox = gb.get_object("box7") as Gtk.Box;
            finish_button = gb.get_object("finish_button") as Gtk.Button;
            finish_button.label = _("Done");
            waitbox = new Gtk.Box(Orientation.VERTICAL, 5);
            spinner = new Gtk.Spinner();
            import_label = new Gtk.Label("");
            import_label.use_markup = true;
            import_label.justify = Justification.CENTER;
            import_label.label = 
                "<span size=\"large\">" + 
                Markup.printf_escaped(_("Please wait while media is added to your library!")) + "\n" +
                Markup.printf_escaped(_("You can start listening to your music by selecting '%s'").printf(
                    Markup.printf_escaped(finish_button.label))) +
                "</span>";
            waitbox.pack_start(spinner, true, true, 0);
            waitbox.pack_start(import_label, true, true, 0);
            addmore_button = gb.get_object("addmore_button") as Gtk.Button;
            addmore_button.label = _("Add more media folders");
            global.notify["media-import-in-progress"].connect( () => {
                addmore_button.sensitive = !global.media_import_in_progress;
                spinner.active = global.media_import_in_progress;
                if(!global.media_import_in_progress) {
                    if(waitbox.parent == bigbox)
                        bigbox.remove(waitbox);
                    if(infobox.parent == null)
                        bigbox.pack_start(infobox, true, true, 0);
                    infobox.show_all();
                }
                else {
                    if(infobox.parent == bigbox)
                        bigbox.remove(infobox);
                    if(waitbox.parent == null)
                        bigbox.pack_start(waitbox, true, true, 0);
                    waitbox.show_all();
                }
            });
            var imported_folders_label = gb.get_object("imported_folders_label") as Gtk.Label;
            imported_folders_label.use_markup = true;
            imported_folders_label.label = 
                "<span size=\"large\"><b>" + 
                Markup.printf_escaped(_("Media Folders:")) +
                "</b></span>";
            addmore_button.clicked.connect(on_button_add_folder_clicked);
            imported_box = gb.get_object("imported_box") as Gtk.Box;
            tv = new TreeView();
            try {
                this.provider = new CssProvider();
                this.provider.load_from_data(CSS, -1);
                tv.get_style_context().add_provider(this.provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
            }
            catch(Error e) {
                print("Xnoise CSS Error: %s\n", e.message);
            }

            imported_box.pack_start(tv, false, false, 0);
            listmodel = new ListStore(Column.COL_COUNT, typeof(Gdk.Pixbuf), typeof(string));
            
            var column = new TreeViewColumn();
            var rendererpb = new CellRendererPixbuf();
            column.pack_start(rendererpb, false);
            column.add_attribute(rendererpb, "pixbuf", Column.ICON);
            tv.insert_column(column, -1);

            column = new TreeViewColumn();
            var renderer = new CellRendererText();
            
            column.pack_start(renderer, true);
            column.add_attribute(renderer, "text", Column.LOCATION);
            column.title = _("Location");
            tv.insert_column(column, -1);
            tv.headers_visible = false;
            tv.can_focus = false;
            tv.get_selection().set_mode(SelectionMode.NONE);
            tv.set_model(listmodel);
            var top_label = new Label("");
            top_label.use_markup = true;
            top_label.label = 
                "<span size=\"xx-large\"><b>" + 
                Markup.printf_escaped(_("Welcome to Xnoise!\n")) + 
                "</b>" + 
                Markup.printf_escaped(_("This is the first time you start xnoise.")) +
                "\n" + 
                Markup.printf_escaped(_("Do you want to import media into your library?")) + 
                "</span>";
            top_label.justify = Justification.CENTER;
            top_box.pack_start(top_label, true, true, 0);
            
            nb = gb.get_object("notebook") as Gtk.Notebook;
            this.pack_start(nb, true, true, 0);
        }
        catch(GLib.Error e) {
            print("ERROR with welcome screen\n");
            var msg = new Gtk.MessageDialog(null, Gtk.DialogFlags.MODAL, Gtk.MessageType.ERROR,
                                            Gtk.ButtonsType.OK,
                                            "Failed to build welcome screen! \n" + e.message);
            msg.run();
            return;
        }
    }

    private static const string CSS = """
            * {
                background-image: none;
                background-color: rgba (0, 0, 0, 0);
            }
    """;
}
