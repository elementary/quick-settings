config_data = configuration_data()
config_data.set_quoted('LOCALEDIR', join_paths(get_option('prefix'), get_option('localedir')))
config_data.set_quoted('GETTEXT_PACKAGE', meson.project_name())
config_file = configure_file(
    input: 'Config.vala.in',
    output: '@BASENAME@',
    configuration: config_data
)

sources = [
    'Indicator.vala',
    'PopoverWidget.vala',
    'DBus' / 'EndSessionDialogServer.vala',
    'DBus' / 'LockInterface.vala',
    'DBus' / 'SeatInterface.vala',
    'DBus' / 'SensorProxy.vala',
    'DBus' / 'SessionInterface.vala',
    'DBus' / 'SystemInterface.vala',
    'DBus' / 'UserInterface.vala',
    'Services' / 'UserManager.vala',
    'Widgets' / 'CurrentUser.vala',
    'Widgets' / 'DarkModeToggle.vala',
    'Widgets' / 'EndSessionDialog.vala',
    'Widgets' / 'PreventSleepToggle.vala',
    'Widgets' / 'RotationToggle.vala',
    'Widgets' / 'SettingsToggle.vala',
    'Widgets' / 'SessionBox.vala',
    'Widgets' / 'TextScale.vala',
    'Widgets' / 'UserList.vala',
    'Widgets' / 'UserRow.vala',
]

shared_module(
    'quick-settings',
    config_file,
    gresource,
    sources,
    dependencies: [
        glib_dep,
        gobject_dep,
        granite_dep,
        gtk_dep,
        gtk_wayland_dep,
        handy_dep,
        wingpanel_dep,
        packagekit_dep,
        pantheon_desktop_shell_dep,
        portal_dep,
        wl_client_dep,
        accountsservice_dep
    ],
    install: true,
    install_dir : wingpanel_indicatorsdir
)
