using GLib;
using Xnoise;
//using DBus;
//using X;

namespace Xnoise {
	class ScreenSaverManager {
		private SSMBackend backend = null;
		public ScreenSaverManager() {
			/*if (!gssm.is_available()) backend = gssm;
			else {*/
				var xdgssm = new XdgSSM();
				if(xdgssm.is_available()) backend = xdgssm;
				/*else {
					var x11ssm = new X11SSM();
					if (x11ssm.is_available()) backend = x11ssm;
				/
			}*/
		
			if(backend == null) return;
			if (!backend.init()) backend = null;
		}
			
		public bool inhibit() {
			message("calling Inhibit");
			if (backend == null) return false;
			return backend.inhibit();
		}
	
		public bool uninhibit() {
			message("calling UnInhibit");
			if (backend == null) return false;
			return backend.uninhibit();
		}
	}

	interface SSMBackend : GLib.Object {
		public abstract bool is_available();
		public abstract bool init();
		public abstract bool inhibit();
		public abstract bool uninhibit();
	}



	class XdgSSM : GLib.Object, SSMBackend {
		private string path = null;
	
		private const string binary_name = "xdg-screensaver";
		private const string inhibit_param = "suspend";
		private const string uninhibit_param = "resume";

		private int exit_status;

		private int get_window_id() {
			var win = Main.instance.main_window.get_window();
			if(win == null) return -1;
			X.ID id = Gdk.x11_drawable_get_xid(win);
			return (int)id;
		}
		
		private bool get_path() {
			string ret = null;
			ret = Environment.find_program_in_path(binary_name);
			if (ret != null) {
				path = ret;
				return true;
			}
			return false;
		}
	
		public bool is_available() {
			return get_path();
		}

		public bool init() {
			if (path == null) return get_path();
			return true;
		}

		public bool inhibit() {
			int id = get_window_id();
			print ("%i", id);
			try {
				Process.spawn_sync (null, {path, inhibit_param, get_window_id().to_string()}, null, 
				                    SpawnFlags.STDOUT_TO_DEV_NULL, 
				                    null, 
				                    null, 
				                    null, 
				                    out exit_status);
			}
			catch (GLib.Error e) {
				error("Failed to inhibit screensaver using xdg-screensaver: %s", e.message);
				return false;
			}
		
			if(exit_status == 0) return true;
			return true;
		}

		public bool uninhibit() {
			try {
				Process.spawn_sync (null, {path, uninhibit_param, get_window_id().to_string()}, null, 
				                    SpawnFlags.STDOUT_TO_DEV_NULL, 
				                    null, 
				                    null, 
				                    null, 
				                    out exit_status);
			}
			catch (GLib.Error e) {
				error("Failed to uninhibit screensaver using xdg-screensaver: %s", e.message);
				return false;
			}
		
			if(exit_status == 0) return true;
			return false;
		}
	}

	/*
	//requires dbus
	 class GnomeSSM : GLib.Object, SSMBackend {
		private const string GS_SERVICE = "org.gnome.ScreenSaver";
		private const string GS_PATH = "/";
		private const string GS_INTERFACE = "org.gnome.ScreenSaver";

		private DBus.Connection conn;
		private dynamic DBus.Object gs = null;
		private uint32 cookie;

		public bool is_available() {
			return true;
		}

		public bool init() {
			message("connecting to session bus");
			try {
				conn = DBus.Bus.get (DBus.BusType.SESSION);
			}
			catch (DBus.Error e) {
				error ("Failed to connect to session bus: %s", e.message);
				return false;
			}
		
			message("getting dbus object for gnome-screensaver");
			gs = conn.get_object (GS_SERVICE, GS_PATH, GS_INTERFACE);
			if (gs == null) {
				error ("Failed to retrieve dbus object %s%s%s", GS_SERVICE, GS_PATH, GS_INTERFACE);
				return false;
			}
			return true;
		}
	
		public bool inhibit() {
			try {
				gs.Inhibit("xnoise", "Fullscreen multimedia playback", out cookie); 
			}
			catch (DBus.Error e) {
				error ("Failed to call Inhibit: %s", e.message);
				return false;
			}
			return true;
		}
	
		public bool uninhibit() {
			try {
				gs.UnInhibit(cookie);
			}
			catch (DBus.Error e) {
				error ("Failed to call UnInhibit: %s", e.message);
				return false;
			}
			return true;
		}
	}


	// needs x11.vapi from svn
	class X11SSM : GLib.Object, SSMBackend {
		private Display dp = null;
	
		private int timeout;
		private int interval;
		private int prefer_blanking;
		private int allow_exposure;

		public bool is_available() {
			return init();
		}
	
		public bool init() {
			dp = new Display();
			if (dp == null) return false;
			return true;
		}
	
		public bool inhibit() {
			dp.lock_display();
			dp.get_screensaver(out timeout, out interval, out prefer_blanking, out allow_exposure);
			dp.set_screensaver(0, 0, 0, 0);
			dp.unlock_display();
			return true;
		}
	
		public bool uninhibit() {
			dp.lock_display();
			dp.set_screensaver(timeout, interval, prefer_blanking, allow_exposure);
			dp.unlock_display();
			return true;
		}
	}
	*/
}

