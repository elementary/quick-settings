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
    'Widgets' / 'SettingsToggle.vala'
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
        wingpanel_dep
    ],
    install: true,
    install_dir : wingpanel_indicatorsdir
)
