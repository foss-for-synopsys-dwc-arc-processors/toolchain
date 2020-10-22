How to Use Custom Toolchain
===========================

You might want to use an external toolchain (for example, built for a
particular CPU configuration) instead of the one shipped with the IDE
installer. Currently there is only one way this can be done: external toolchain
location should be added to the beginning of the ``PATH`` environment variable.

To create a project using external toolchain added to ``PATH``, open C project
creation dialog and select one of ARC project types. For the list of available
project types and toolchains supported by them, see :ref:`ARC Project
Templates <arc-project-templates>`. Note that project should be created with a
target toolchain already in the PATH, otherwise it will use standard library headers
from the original toolchain with which it was created.

As it is explained on :ref:`ARC Project Templates page <arc-project-templates>`, IDE
allows you to create projects only if supported toolchains compiler is found in
``PATH`` or in ``../bin/`` directory relative to Eclipse executable, so if there are
other toolchains present there except your external toolchain, projects that
support them will be available too. However your external toolchain will hide
other toolchains present in ``PATH`` or ``../bin/`` that contain the same tools as
yours, so you will not be able to create projects that use them.