project(
    'io.elementary.quick-settings',
    'vala', 'c'
)

i18n = import('i18n')

add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format (meson.project_name()), language:'c')

glib_dep = dependency ('glib-2.0')
granite_dep = dependency ('granite-7', version: '>=7.0.0')
gtk_dep = dependency ('gtk4')

subdir('src')
