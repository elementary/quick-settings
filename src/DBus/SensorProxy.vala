[DBus (name = "net.hadess.SensorProxy")]
private interface QuickSettings.SensorProxy : DBusProxy {
    public abstract bool has_accelerometer { get; }
}
