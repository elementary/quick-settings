[DBus (name = "io.elementary.pantheon.AccountsService")]
private interface QuickSettings.Pantheon.AccountsService : Object {
    public abstract int prefers_accent_color { get; set; }
    public abstract int prefers_color_scheme { get; set; }
}

[DBus (name = "org.freedesktop.Accounts")]
interface QuickSettings.FDO.Accounts : Object {
    public abstract string find_user_by_name (string username) throws GLib.Error;
}
