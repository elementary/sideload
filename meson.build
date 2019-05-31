project('io.elementary.sideload', 'vala', 'c')

gnome = import('gnome')
i18n = import('i18n')

add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format (meson.project_name()), language:'c')

executable(
    meson.project_name(),
    'src/Views/ProgressView.vala',
    'src/Application.vala',
    'src/MainWindow.vala',
    dependencies: [
        # dependency('appstream'),
        dependency('glib-2.0'),
        dependency('gobject-2.0'),
        dependency('granite', version: '>=0.5'),
        dependency('gtk+-3.0'),
    ],
    install : true
)

subdir('data')
# subdir('po')

