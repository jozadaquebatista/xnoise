/* xnoise-main-view-notebook.vala
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




public class Xnoise.MainViewNotebook : Gtk.Notebook {
    
    private HashTable<string,IMainView> main_views = new HashTable<string,IMainView>(str_hash, str_equal);
    
    public MainViewNotebook() {
        this.set_border_width(0);
        this.show_border = false;
        this.show_tabs   = false;
    }
    
    public void add_main_view(Xnoise.IMainView view) {
        //print("##add view: %s\n", view.get_view_name());
        if(main_views.lookup(view.get_view_name()) != null) {
            print("Main view is already there\n");
            return;
        }
        main_views.insert(view.get_view_name(), view);
        this.append_page(view);
    }
    
    public void remove_main_view(Xnoise.IMainView view) {
        if(main_views.lookup(view.get_view_name()) == null) {
            print("Main view is already gone\n");
            return;
        }
        this.remove_page(this.page_num(view));
        main_views.remove(view.get_view_name());
    }

    public bool select_main_view(string? name) {
        //print("##select main view: %s\n", name);
        if(name == null || name == "")
            return false;
        if(main_views.lookup(name) == null) {
            print("Selected main view is not available\n");
            return false;
        }
        //print("select %s on page %d\n", name, this.page_num(main_views.lookup(name)));
        this.set_current_page(this.page_num(main_views.lookup(name)));
        return true;
    }

    public string? get_current_main_view_name() {
        if(this.get_n_pages() == 0)
            return null;
        
        Xnoise.IMainView? mv = (Xnoise.IMainView)this.get_nth_page(this.get_current_page());
        if(mv != null)
            return mv.get_view_name();
        else
            return null;
    }
}
