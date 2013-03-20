/* xnoise-base-object.vala
 *
 * Copyright (C) 2013  Jörn Magens
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


// reference tracking for objects

public abstract class Xnoise.BaseObject : GLib.Object {
    
#if REF_TRACKING_ENABLED
    
    private static HashTable<unowned string, int>? ht = null;
    
    protected BaseObject() {
        lock(ht) {
            if (ht == null)
                ht = new HashTable<unowned string, int>(direct_hash, direct_equal);
            unowned string classname = get_classname();
            //print("classname: %s\n", classname);
            ht.insert(classname, ht.lookup(classname) + 1);
        }
    }
    
    ~BaseObject() {
        lock(ht) {
            unowned string classname = get_classname();
            int count = ht.lookup(classname) - 1;
            if (count == 0)
                ht.remove(classname);
            else
                ht.insert(classname, count);
        }
    }
    
    private unowned string get_classname() {
        return get_class().get_type().name();
    }
    
    public static void print_object_dump() {
        if (ht == null || ht.size() == 0) {
            print("No references left.\n");
            return;
        }
        
        List<unowned string> list = new List<unowned string>();
        list = ht.get_keys();
        list.sort(strcmp);
        foreach(unowned string classname in list)
            print("  %10d \t%s\n", ht.lookup(classname), classname);
    }
    
#else
    
    protected BaseObject() {
    }
    
#endif
}

