
public class Xnoise.DockableMediaManager {
    public HashTable<string,Xnoise.DockableMedia> table;
    
    public signal void media_removed (string key);
    public signal void media_inserted (string key);
    public signal void category_removed (DockableMedia.Category category);
    public signal void category_inserted (DockableMedia.Category category);

    public DockableMediaManager() {
        table = new HashTable<string,Xnoise.DockableMedia>(str_hash, str_equal);
    }

    /*
    Removes a media source by its name.    
    */
    public bool remove (string key) {
        DockableMedia d = this.lookup(key);
        DockableMedia.Category c = 0;
         
        if(d != null)
            c = d.category();
        else
            return false;
        print("category : %s :: size: %d\n", c.to_string(), this.size_of_category(c));
        media_removed(key);
        if(this.size_of_category(c) == 1)
            category_removed(c);
        table.remove(key);
//        if(table.remove(key)) {
//            media_removed(key);
        return true;
//        }
//        else
//            return false;
    }

    /*
    Returns the media source for key if found, else null.
    */
    public unowned Xnoise.DockableMedia lookup (string key) {
        return table.lookup(key);
    }

    /*
    Returns a list of the names of all media sources.
    */
    public List<weak string> get_keys () {
        return table.get_keys();
    }
     
    /*
    Insert a new media source.
    */
    public void insert(Xnoise.DockableMedia val) {
        string name = val.name();
        table.insert(name, val);
        
        // the just added media source is the first of its category
        if(size_of_category(val.category()) == 1) 
            category_inserted(val.category());
        media_inserted(name);
    }
    
    /*
    Returns the number of registered media sources belonging to a category.
    */  
    public int size_of_category (DockableMedia.Category category) {
        int count = 0;
        foreach(DockableMedia d in table.get_values()) {
            if (d.category() == category)
                ++count;
        }
        return count;
   }

   /*
   Returns a list of the categories which have a media source belonging to them registered.
   */   
   public List<DockableMedia.Category> get_existing_categories() {
        List<DockableMedia.Category> l = new List<DockableMedia.Category>();
        
        foreach(DockableMedia d in table.get_values()) {
            bool already_counted = false;
            foreach(DockableMedia.Category c in l)
                if(d.category() == c)
                    already_counted = true;
            if(!already_counted)
                l.append(d.category());        
        }
        return l;
   }
   
   public List<DockableMedia> get_media_for_category(DockableMedia.Category category) {
        List<DockableMedia> l = new List<DockableMedia>();
        
        foreach(DockableMedia d in table.get_values()) {
            if(d.category() == category)
                l.append(d);
        }
        return l;
    }
}

