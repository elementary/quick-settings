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
    'DBus' / 'AccountsService.vala',
    'DBus' / 'EndSessionDialogServer.vala',
    'DBus' / 'LockInterface.vala',
    'DBus' / 'SensorProxy.vala',
    'DBus' / 'SessionInterface.vala',
    'DBus' / 'SystemInterface.vala',
    'Views' / 'A11yView.vala',
    'Widgets' / 'DarkModeToggle.vala',
    'Widgets' / 'EndSessionDialog.vala',
    'Widgets' / 'RotationToggle.vala',
    'Widgets' / 'SettingsToggle.vala',
    'Widgets' / 'SessionBox.vala'
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
        handy_dep,
        wingpanel_dep
    ],
    install: true,
    install_dir : wingpanel_indicatorsdir
)
