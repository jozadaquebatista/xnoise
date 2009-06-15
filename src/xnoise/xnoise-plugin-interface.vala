
public interface Xnoise.IPlugin : GLib.Object {
	public abstract void activate(ref weak Main xn);
	public abstract string pname { construct set; get; }
}

