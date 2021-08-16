project(
    'io.elementary.sideload', 
    'vala', 'c',
    version: '6.0.0'
)

gnome = import('gnome')
i18n = import('i18n')

add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format (meson.project_name()), language:'c')

vapi_dir = join_paths(meson.current_source_dir(), 'vapi')
add_project_arguments(['--vapidir', vapi_dir], language: 'vala')

config_data = configuration_data()
config_data.set_quoted('LOCALEDIR', join_paths(get_option('prefix'), get_option('localedir')))
config_data.set_quoted('GETTEXT_PACKAGE', meson.project_name())
config_file = configure_file(
    input: 'src/Config.vala.in',
    output: '@BASENAME@',
    configuration: config_data
)

executable(
    meson.project_name(),
    config_file,
    'src/Utils/AsyncMutex.vala',
    'src/Views/AbstractView.vala',
    'src/Views/ErrorView.vala',
    'src/Views/MainView.vala',
    'src/Views/ProgressView.vala',
    'src/Views/SuccessView.vala',
    'src/Application.vala',
    'src/MainWindow.vala',
    'src/FlatpakFile.vala',
    'src/FlatpakRefFile.vala',
    'src/FlatpakBundleFile.vala',
    dependencies: [
        dependency ('flatpak', version: '>=1.1.2'),
        dependency ('glib-2.0'),
        dependency ('gobject-2.0'),
        dependency ('granite', version: '>=5.4.0'),
        dependency ('gtk+-3.0'),
        dependency ('libhandy-1'),
        dependency ('libxml-2.0'),
    ],
    install : true
)

subdir('data')
subdir('po')

meson.add_install_script('meson/post_install.py')

