#!/usr/bin/env python3

import os
import subprocess

mimedir = os.path.join(os.environ['MESON_INSTALL_PREFIX'], 'share', 'mime')

if not os.environ.get('DESTDIR'):
    print('Updating desktop database...')
    subprocess.call(['update-desktop-database'])
