gresource = gnome.compile_resources(
    'gresource',
    'quick-settings.gresource.xml'
)

i18n.merge_file(
    input: 'quick-settings.metainfo.xml.in',
    output: meson.project_name() + '.metainfo.xml',
    po_dir: meson.source_root() / 'po' /  'extra',
    type: 'xml',
    install: true,
    install_dir: datadir / 'metainfo',
)

install_data(
    'quick-settings.gschema.xml',
    install_dir: datadir / 'glib-2.0' / 'schemas'
)
