vala_files = files(
    'DisplayWidget.vala',
    'Indicator.vala',
    'MainWidget.vala'
)

executable(
    meson.project_name(),
    vala_files,
    dependencies: [
        glib_dep,
        granite_dep,
        gtk_dep
    ],
    install: true
)
