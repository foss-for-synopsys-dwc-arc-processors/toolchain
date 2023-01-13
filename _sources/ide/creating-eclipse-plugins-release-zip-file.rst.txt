Creating Eclipse plugins release zip file
=========================================

Following is an guide how to create distributable release file for
Eclipse for GNU Toolchain for ARC.

#. Create tag for release: ``$ git tag arc-2014.12``
#. Clean all past artifacts: ``$ git clean -dfx``
#. Ensure that no files are modified: ``$ git reset --hard HEAD``
#. Start Eclipse
#. Build plugins. That is important, because even when it is not done,
   "publishing step" will somehow succeed, but will produce plugins that
   are only partially functional.

    #. Make sure that "Project / Build Automatically" is checked
    #. Go to "Project / Clean"
    #. Check "Clean all projects"
    #. Press OK button

#. Open ``site.xml`` file of "ARC GNU Eclipse Update Site"
#. Press "Build All"
#. Zip contents of "updatesite" folder. Note that contents of this folder
   should be zipped, not the folder itself. Files ``.gitignore`` and ``.project``
   should be excluded from zip:
   ``zip -r arc_gnu_2015.12_ide_plugins.zip artifacts.jar content.jar features/ plugins/ site.xml``
