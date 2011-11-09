/* xnoise-mpris.vala
 *
 * Copyright (C) 2011 Jörn Magens
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
 * Jörn Magens
 */

using Gtk;
using Lastfm;

using Xnoise;
using Xnoise.PluginModule;


public class Xnoise.Lfm : GLib.Object, IPlugin {
	public Main xn { get; set; }
	private unowned PluginModule.Container _owner;
	private Session session;
	private Track t;
	
	public PluginModule.Container owner {
		get {
			return _owner;
		}
		set {
			_owner = value;
		}
	}
	
	public string name { get { return "lastfm"; } }
	
	public signal void login_state_change();
	
	public bool init() {
		owner.sign_deactivated.connect(clean_up);
		
		session = new Lastfm.Session(
		   Lastfm.Session.AuthenticationType.MOBILE,   // session authentication type
		   "a39db9ab0d1fb9a18fabab96e20b0a34",         // xnoise api_key for noncomercial use
		   "55993a9f95470890c6806271085159a3",         // secret
		   null//"de"                                  // language TODO
		);
		c = session.notify["logged-in"].connect( () => {
			Idle.add( () => {
				login_state_change();
				return false;
			});
		});
		d = session.login_successful.connect( (sender, un) => {
			print("Lastfm plugin logged in %s successfully\n", un); // TODO: real feedback needed
		});
		string username = Xnoise.Params.get_string_value("lfm_user");
		string password = Xnoise.Params.get_string_value("lfm_pass");
		if(username != "" && password != "")
			this.login(username, password);
		
		a = global.notify["current-title"].connect(on_current_track_changed);
		b = global.notify["current-artist"].connect(on_current_track_changed);
		return true;
	}
	
	private ulong a = 0;
	private ulong b = 0;
	private ulong c = 0;
	private ulong d = 0;
	
	public void uninit() {
		clean_up();
	}

	private void clean_up() {
		session.abort();
		global.disconnect(a);
		global.disconnect(b);
		session.disconnect(c);
		session.disconnect(d);
		session = null;
	}
	
	~Mpris() {
	}

	public Gtk.Widget? get_settings_widget() {
		var w = new LfmWidget(this);
		return w;
	}

	public bool has_settings_widget() {
		return true;
	}
	
	public void login(string username, string password) {
		Idle.add( () => {
			session.login(username, password);
			return false;
		});
	}
	
	public bool logged_in() {
		return this.session.logged_in;
	}
	
	private uint scrobble_source = 0;
	private ulong scrobble_reply = 0;
	
	private void on_current_track_changed(GLib.Object sender, ParamSpec p) {
		//scrobble
		if(!session.logged_in)
			return;
		if(global.current_title != null && global.current_artist != null) {
			if(scrobble_source != 0) 
				Source.remove(scrobble_source);
			scrobble_source = Timeout.add_seconds(15, () => {
				t = session.factory_make_track(global.current_artist, global.current_album, global.current_title);
				scrobble_reply = t.scrobbled.connect( (sender, ar, al, tr, su) => {
					print("scrobbeled %s-%s-%s %s\n", ar, al, tr, (su == true ? "successfully" : "unsuccessfully"));
					t.disconnect(scrobble_reply);
					scrobble_reply = 0;
				});
				var dt = new DateTime.now_utc();
				int64 start_time = dt.to_unix();
				t.scrobble(start_time);
				scrobble_source = 0;
				return false;
			});
		}
	}
}


public class Xnoise.LfmWidget: Gtk.VBox {
	private unowned Main xn;
	private unowned Xnoise.Lfm lfm;
	private Entry user_entry;
	private Entry pass_entry;
	private Label feedback_label;
	private Button b;
	
	public LfmWidget(Xnoise.Lfm lfm) {
		GLib.Object(homogeneous:false, spacing:10);
		this.lfm = lfm;
		this.xn = Main.instance;
		setup_widgets();
		
		this.lfm.login_state_change.connect(do_user_feedback);
		
		user_entry.text = Xnoise.Params.get_string_value("lfm_user");
		pass_entry.text = Xnoise.Params.get_string_value("lfm_pass");
		b.clicked.connect(on_entry_changed);
	}

	private void do_user_feedback() {
		//print("do_user_feedback\n");
		if(this.lfm.logged_in()) {
			feedback_label.set_markup("<b><i>%s</i></b>".printf(_("User logged in!")));
			feedback_label.set_use_markup(true);
		}
		else {
			feedback_label.set_markup("<b><i>%s</i></b>".printf(_("User not logged in!")));
			feedback_label.set_use_markup(true);
		}
	}
	
	private string username_last;
	private string password_last;
	
	private void on_entry_changed() {
		//print("take over entry\n");
		string username = "", password = "";
		if(user_entry.text != null)
			username = user_entry.text.strip();
		if(pass_entry.text != null)
			password = pass_entry.text.strip();
		if(username_last == user_entry.text.strip() && password_last == pass_entry.text.strip())
			return; // no need to spam!
		if(username != "" && password != "") {
			//print("got login data\n");
			Xnoise.Params.set_string_value("lfm_user", username);
			Xnoise.Params.set_string_value("lfm_pass", password);
			username_last = username;
			password_last = password;
			Idle.add( () => {
				Xnoise.Params.write_all_parameters_to_file();
				return false;
			});
			do_user_feedback();
			lfm.login(username, password);
		}
	}
	
	private void setup_widgets() {
		var title_label = new Label("<b>%s</b>".printf(_("Please enter your lastfm username and password.")));
		title_label.set_use_markup(true);
		title_label.set_single_line_mode(true);
		title_label.set_alignment(0.5f, 0.5f);
		title_label.set_ellipsize(Pango.EllipsizeMode.END);
		title_label.ypad = 10;
		this.pack_start(title_label, false, false, 0);
		
		var hbox1 = new HBox(false, 2);
		var user_label = new Label("%s".printf(_("Username:")));
		hbox1.pack_start(user_label, false, false, 0);
		user_entry = new Entry();
		hbox1.pack_start(user_entry, true, true, 0);
		
		var hbox2 = new HBox(false, 2);
		var pass_label = new Label("%s".printf(_("Password:")));
		hbox2.pack_start(pass_label, false, false, 0);
		pass_entry = new Entry();
		pass_entry.set_visibility(false);
		
		hbox2.pack_start(pass_entry, true, true, 0);
		
		var sizegroup = new Gtk.SizeGroup(SizeGroupMode.HORIZONTAL);
		sizegroup.add_widget(user_label);
		sizegroup.add_widget(pass_label);
		
		this.pack_start(hbox1, false, false, 4);
		this.pack_start(hbox2, false, false, 4);
		
		//feedback
		feedback_label = new Label("<b><i>%s</i></b>".printf(_("User not logged in!")));
		if(this.lfm.logged_in()) {
			feedback_label.set_markup("<b><i>%s</i></b>".printf(_("User logged in!")));
		}
		else {
			feedback_label.set_markup("<b><i>%s</i></b>".printf(_("User not logged in!")));
		}
		feedback_label.set_use_markup(true);
		feedback_label.set_single_line_mode(true);
		feedback_label.set_alignment(0.5f, 0.5f);
		feedback_label.ypad = 20;
		this.pack_start(feedback_label, false, false, 0);
		
		b = new Button();
		b.set_label(_("Apply"));
		this.pack_start(b, true, true, 0);
		this.border_width = 4;
	}
}

