/* xnoise-serial-button.vala
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

public class Xnoise.SerialButton : Gtk.Box {
    private CssProvider provider;
    private int _selected_idx = -1;
    
    public signal void sign_selected(int idx);
    
    private class SerialItem : Gtk.ToggleButton {
        private unowned SerialButton sb;
        
        public SerialItem(SerialButton sb) {
            
            this.sb = sb;
            
            this.set_can_focus(false);
            this.get_style_context().add_provider(sb.provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        }
    }
    
    public SerialButton() {
        GLib.Object(orientation:Orientation.HORIZONTAL, spacing:0);
        this.set_homogeneous(true);
        
        try {
            this.provider = new CssProvider();
            this.provider.load_from_data(CSS, -1);
            this.get_style_context().add_class("XnoiseSerialButton");
        }
        catch(Error e) {
            print("Xnoise CSS Error: %s\n", e.message);
        }
    }

    public int selected_idx {
        get { return _selected_idx; }
        set { select(value); }
    }

    public int item_count {
        get { return (int)this.get_children().length(); }
    }

    public int insert(string? txt) {
        if(txt == null)
            return -1;
        
        var si = new SerialItem(this);
        si.add(new Gtk.Label(txt));
        this.add(si);
        
        si.button_press_event.connect( () => {
            this.select(get_children().index((Gtk.Widget)si));
            return true;
        });
        si.show_all();
        
        int cnt = this.item_count;
        if(cnt == 1)
            this.select(0);
        
        return cnt - 1;
    }

    public void select(int idx, bool emit_signal = true) {
        if(idx < 0 ) //|| idx >= this.item_count || _selected_idx == idx 
            return;
        
        SerialItem? si;
        
        if(_selected_idx >= 0) {
            si = (SerialItem) get_at_index(_selected_idx);
            if(si != null)
                si.set_active(false);
        }
        _selected_idx = idx;
        si = (SerialItem) get_at_index(idx);
        if(si != null)
            si.set_active(true);
        
        if(emit_signal)
            this.sign_selected(idx);
    }

    public new void set_sensitive(int idx, bool sensitive_status) {
        if(idx < 0 || idx >= this.item_count)
            return;
        
        SerialItem? si = (SerialItem) get_at_index(idx);
        
        if(si != null)
            si.set_sensitive(sensitive_status);
    }

    public void del(int idx) {
        Gtk.Widget? w = get_at_index(idx);
        if(w != null) {
            this.remove(w);
            w.destroy();
            if(_selected_idx >= 0 && idx == _selected_idx)
                this.select(0);
        }
        else {
            print("Widget not found for index!\n");
        }
    }
    
    private Gtk.Widget? get_at_index(int idx) {
        return this.get_children().nth_data(idx);
    }
    
    private static const string CSS = """
        .XnoiseSerialButton .button {
            -GtkToolbar-button-relief:  normal;
            border-radius:              0px 0px 0px 0px;
            border-style:               solid;
            border-width:               1px 0px 1px 1px;
            -unico-outer-stroke-width:  1px 0px 1px 0px;
            -unico-outer-stroke-radius: 0px 0px 0px 0px;
        }
        
        .XnoiseSerialButton .button:active,
        .XnoiseSerialButton .button:insensitive {
            -unico-outer-stroke-width:  1px 0px 1px 0px;
        }

        .XnoiseSerialButton .button:first-child {
            border-radius:              3px 0px 0px 3px;
            border-width:               1px 0px 1px 1px;
            -unico-outer-stroke-width:  1px 0px 1px 1px;
        }

        .XnoiseSerialButton .button:last-child {
            border-radius:              0px 3px 3px 0px;
            border-width:               1px;
            -unico-outer-stroke-width:  1px 1px 1px 0px;
        }
    """;
}

