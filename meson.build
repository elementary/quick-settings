project(
    'io.elementary.quick-settings',
    'vala', 'c',
    version: '1.4.0'
)

gnome = import('gnome')
i18n = import('i18n')
prefix = get_option('prefix')
libdir = prefix / get_option('libdir')
datadir = prefix / get_option('datadir')

add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()), language:'c')
add_project_arguments('-DG_LOG_DOMAIN="@0@"'.format(meson.project_name()), language:'c')

glib_dep = dependency('glib-2.0')
gobject_dep = dependency('gobject-2.0')
granite_dep = dependency('granite-7', version: '>=7.0.0')
gtk_dep = dependency('gtk4')
gtk_wayland_dep = dependency('gtk4-wayland')
handy_dep = dependency('libadwaita-1', version: '>=1.0')
packagekit_dep = dependency('packagekit-glib2')
wingpanel_dep = dependency('wingpanel-8')
wingpanel_indicatorsdir = wingpanel_dep.get_pkgconfig_variable('indicatorsdir', define_variable: ['libdir', libdir])
wl_client_dep = dependency('wayland-client')
portal_dep = dependency('libportal')
accountsservice_dep = dependency('accountsservice')

subdir('protocol')
subdir('data')
subdir('po')
subdir('src')

gnome.post_install(glib_compile_schemas: true)
