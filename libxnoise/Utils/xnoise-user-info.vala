/* xnoise-user-info.vala
 *
 * Copyright (C) 2009-2010  Jörn Magens
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
 * 	Jörn Magens
 */

//Keep this class static, so it can handle the old info bar messages and 
// remove them as soon as they are due.

using Gtk;


public class Xnoise.UserInfo : GLib.Object {
	
	// Set how the infobar should be removed
	public enum RemovalType {
		CLOSE_BUTTON = 0,      //Info is removed, if close button is clicked
		TIMER,                 //Info is removed, if timer has elapsed
		TIMER_OR_CLOSE_BUTTON, //Info is removed, if timer has elapsed or close button is clicked
		EXTERNAL               //Info is removed, if external function is called with messge id; no remove button available and no timer used
	}

	// Set the type of content. Used to choose picture/spinner
	public enum ContentClass {
		INFO = 0,
		WAIT,
		WARNING,
		QUESTION,
		CRITICAL
	}

	public signal void sign_removed_info_bar(uint id);

	// delegate type used to place the info bar
	public delegate void AddInfoBarDelegateType(InfoBar ibar);

	private unowned AddInfoBarDelegateType add_info_bar;
	private HashTable<uint, Xnoise.InfoBar> info_messages;
	private uint id_count;

	public UserInfo(AddInfoBarDelegateType func) {
		add_info_bar = func;
		id_count = 1;
		info_messages = new HashTable<uint, Xnoise.InfoBar>(direct_hash, direct_equal);
	}

	private uint get_min(GLib.List<uint> list) {
		uint ret = list.data;
		foreach(uint val in list) {
			if(val < ret)
				ret = val;
		}
		return ret;
	}
	
	private void popdown_oldest() {
		GLib.List<uint> keys = info_messages.get_keys();
		if(keys == null)
			return;
		uint id = get_min(keys);
		if(id == 0)
			return;
		popdown(id);
	}
	
	public void enable_close_button_by_id(uint id, bool enable) {
		Xnoise.InfoBar? bar = info_messages.lookup(id);
		
		if(bar == null)
			return;
			
		bar.enable_close_button(enable);
	}
	
	public void update_symbol_widget_by_id(uint id, UserInfo.ContentClass cc) {
		Xnoise.InfoBar? bar = info_messages.lookup(id);
		
		if(bar == null)
			return;
			
		bar.update_symbol_widget(cc);
	}
	
	public void update_text_by_id(uint id, string txt, bool bold = true) {
		Xnoise.InfoBar? bar = info_messages.lookup(id);
		
		if(bar == null)
			return;
			
		bar.update_text(txt, bold);
	}
	
	public void update_extra_widget_by_id(uint id, Gtk.Widget? widget) {
		Xnoise.InfoBar? bar = info_messages.lookup(id);
		
		if(bar == null)
			return;
			
		bar.update_extra_widget(widget);
	}
	
	public unowned Gtk.Widget? get_extra_widget_by_id(uint id) {
		Xnoise.InfoBar? bar = info_messages.lookup(id);
		
		if(bar == null)
			return null;
			
		return bar.get_extra_widget();
	}
	
	/*
	 * Hide infobar and remove it from the internal list
	 */
	public void popdown(uint id) {
		Xnoise.InfoBar? bar = info_messages.lookup(id);
		
		if(bar == null)
			return;
		
		info_messages.remove(id);
		
		Idle.add( () => {
			if(bar == null)
				return false;
			bar.hide();
			bar.destroy();
			bar = null;
			return false;
		});
		
		sign_removed_info_bar(id);
	}

	/*
	 * RemovalType:              how should the infobar be removed
	 * ContentClass:             what is the classification of the content
	 * info_text:                Text to display
	 * appearance_time_seconds:  time used for the case a timer is used popdown
	 * extra_widget:             for example a button to reply a question
	 * returns:                  messge id for removal of info bars
	 */
	public uint popup(RemovalType removal_type,
	                 ContentClass content_class,
	                 string info_text = "",
	                 bool bold = true, 
	                 int appearance_time_seconds = 2, 
	                 Widget? extra_widget = null) {
		
		uint current_id = id_count;
		id_count++;
		
		var bar = new Xnoise.InfoBar(this, 
		                             content_class, 
		                             removal_type, 
		                             current_id,
		                             appearance_time_seconds, 
		                             info_text,
		                             bold,
		                             extra_widget);

		info_messages.insert(current_id, bar);
		this.add_info_bar(bar); 
		bar.show_all();
		
		if(info_messages.size() > 3)
			this.popdown_oldest();
		
		return current_id;
	}
}

