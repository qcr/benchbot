# Python manager for BenchBot Add-ons
import json
import re
import os
from shutil import rmtree
from subprocess import run

DEFAULT_INSTALL_LOCATION = '.'
DEFAULT_STATE_PATH = '.state'

ENV_INSTALL_LOCATION = 'INSTALL_LOCATION'
ENV_STATE_PATH = 'STATE_PATH'

FILENAME_DEPENDENCIES = '.dependencies'
FILENAME_REMOTE = '.remote'


def _abs_path(path):
    return (path if path.startswith('/') else os.path.abspath(
        os.path.join(os.path.dirname(__file__), path)))


def _addon_path(repo_user, repo_name):
    return os.path.join(_install_location(), repo_user, repo_name)


def _install_location():
    return _abs_path(
        os.environ.get(ENV_INSTALL_LOCATION, DEFAULT_INSTALL_LOCATION))


def _parse_name(name):
    # Support both 'repo_owner/repo_name' &
    # 'https://github.com/repo_owner/repo_name' syntax
    url = name if name.startswith('http') else 'https://github.com/%s' % name
    repo_user, repo_name = re.search('[^/]*/[^/]*$', url).group().split('/')
    return url, repo_user, repo_name, '%s/%s' % (repo_user, repo_name)


def _state_path():
    return _abs_path(os.environ.get(ENV_STATE_PATH, DEFAULT_STATE_PATH))


def dump_state(state):
    # State is a dictionary with:
    # - keys for each installed addon
    # - each key has: 'hash', 'remote' (if remote content installed), & 'deps'
    #   list
    with open(_state_path(), 'w+') as f:
        json.dump(state, f)


def get_state():
    if os.path.exists(_state_path()):
        with open(_state_path(), 'r') as f:
            return json.load(f)
    return {}


def install_addon(name):
    url, repo_user, repo_name, name = _parse_name(name)
    install_path = _addon_path(repo_user, repo_name)

    print("Installing addon '%s' in '%s':" % (name, _install_location()))

    # Make sure the target location exists
    if not os.path.exists(install_path):
        os.makedirs(install_path)
        print("\tCreated install path './%s'." %
              os.path.relpath(install_path, _install_location()))
    else:
        print("\tFound install path './%s'." %
              os.path.relpath(install_path, _install_location()))

    # Either clone the addon or upgrade to latest
    cmd_args = {
        'shell': True,
        'cwd': install_path,
        'capture_output': True,
    }
    if not os.path.exists(os.path.join(install_path, '.git')):
        ret = run('git clone %s .' % url, **cmd_args)
        if ret.returncode == 0:
            print("\tCloned addon from '%s'." % url)
        else:
            raise RuntimeError("Failed to clone '%s' from '%s'.\n"
                               "Are you sure the repository exists?" %
                               (name, url))
        current = run('git rev-parse HEAD',
                      **cmd_args).stdout.decode('utf8').strip()
    else:
        run('git fetch --all', **cmd_args)
        current = run('git rev-parse HEAD',
                      **cmd_args).stdout.decode('utf8').strip()
        latest = run('git rev-parse origin/HEAD',
                     **cmd_args).stdout.decode('utf8').strip()
        if current == latest:
            print("\tNo action - latest already installed.")
        else:
            run('git reset --hard origin/HEAD')
            print("\tUpgraded from '%s' to '%s'." % (current[:8], latest[:8]))

    # Fetch remote data if required
    file_remote = os.path.join(install_path, FILENAME_REMOTE)
    if os.path.exists(file_remote):
        with open(file_remote, 'r') as f:
            remote = f.read()[0].strip()
            print("\tFound remote content to install: %s" % remote)
            if 'remote' not in state[name] or state[name]['remote'] != remote:
                print("\tRemote content is new. Fetching ...")
                # TODO actually get the content...
                print("\tFetched.")
                state = get_state()
                state[name]['remote'] = remote
                dump_state(state)
            else:
                print("\tNo action - remote content is already installed.")

    # Install all dependencies
    file_deps = os.path.join(install_path, FILENAME_DEPENDENCIES)
    if os.path.exists(file_deps):
        with open(file_deps, 'r') as f:
            deps = f.read().splitlines()
    else:
        deps = []
    ret = [name]
    for d in deps:
        ret.extend(install_addon(d))

    # Update the saved state
    state = get_state()
    if name not in state:
        state[name] = {}
    state[name]['hash'] = current
    state[name]['deps'] = deps
    dump_state(state)
    return ret


def install_addons(string, remove_extras=False):
    installed_list = []
    for a in string.split(','):
        installed_list.extend(install_addon(a))
    return installed_list


def print_state():
    pass


def remove_addon(name):
    url, repo_user, repo_name, name = _parse_name(name)
    install_path = _addon_path(repo_user, repo_name)
    install_parent = os.path.dirname(install_path)

    # Confirm the addon exists
    if not os.path.exists(install_path):
        raise RuntimeError(
            "Are you sure addon '%s' is installed? It was not found at:\n\t%s"
            % (name, install_path))

    # Remove the directory (& parent if now empty)
    print("Removing addon '%s' in '%s':" % (name, _install_location()))
    rmtree(install_path)
    print("\tRemoved installed directory './%s'" %
          os.path.relpath(install_path, _install_location()))
    if os.path.exists(install_parent) and not os.listdir(install_parent):
        os.rmdir(install_parent)
        print("\tRemoved empty parent directory './%s'" %
              os.path.relpath(install_parent, _install_location()))

    # Redump installed state
    state = get_state()
    del state[name]
    dump_state(state)


def remove_addons(string=None):
    if string is None or string == "":
        string = ",".join(get_state().keys())
    if string == "":
        return
    for a in string.split(','):
        remove_addon(a)
