Start the app in the venv with:
  $WORKSPACE/venv_run.sh $WORKSPACE/manage.py
To install package into the venv (editable):
  (inside venv) pip install -e $WORKSPACE
To enable tests during dependency install: export TESTING=1 before running deps step.
To create a global wrapper symlink (opt-in): export CREATE_GLOBAL_SYMLINK=1 before running env step.
