



public class Xnoise.MainViewNotebook : Gtk.Notebook {
    
    private HashTable<string,IMainView> main_views = new HashTable<string,IMainView>(str_hash, str_equal);
    
    public MainViewNotebook() {
        this.set_border_width(0);
        this.show_border = false;
        this.show_tabs   = false;
    }
    
    public void add_main_view(Xnoise.IMainView view) {
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

    public bool select_main_view(string name) {
        if(main_views.lookup(name) == null) {
            print("Selected main view is not available\n");
            return false;
        }
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
