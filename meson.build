project(
    'io.elementary.quick-settings',
    'vala', 'c',
    version: '0.0.1'
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
granite_dep = dependency('granite', version: '>=6.0.0')
gtk_dep = dependency('gtk+-3.0')
handy_dep = dependency('libhandy-1', version: '>=1.0')
wingpanel_dep = dependency('wingpanel')
wingpanel_indicatorsdir = wingpanel_dep.get_pkgconfig_variable('indicatorsdir', define_variable: ['libdir', libdir])

subdir('data')
subdir('po')
subdir('src')

gnome.post_install(glib_compile_schemas: true)
