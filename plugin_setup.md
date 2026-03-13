# Plugin Setup Guide

## Prerequisites

- Care running locally via Docker Compose (`make up`)
- Your plugin repo cloned somewhere on your machine
- Python 3.10+

---

## 1. Clone the plugin

```bash
git clone https://github.com/<your-username>/{{ cookiecutter.plugin_slug }}.git
cd {{ cookiecutter.plugin_slug }}
```

## 2. Connect the Plugin to Care (Docker Setup)

### Step 1 — Create `plug_config.py` in your Care repo

In the root of the `care` repository, create a file called `plug_config.py`:

```python
from plugs.manager import PlugManager
from plugs.plug import Plug

{{ cookiecutter.plugin_slug }} = Plug(
    name="{{ cookiecutter.plugin_slug }}",
    package_name="git+https://github.com/<your-username>/{{ cookiecutter.plugin_slug }}.git",
    # for local development use "./{{ cookiecutter.plugin_slug }}"
    # assuming that the plugin is cloned in care at the same level as manage.py
    version="@main",  # or a specific tag like @v0.1.0 or "" for local
    configs={
        # Add any plugin config variables here
        # "MY_CONFIG_KEY": "value",
    },
)

plugs = [{{ cookiecutter.plugin_slug }}]
manager = PlugManager(plugs)
```

Tweak the code in `plugs/manager.py` to update the pip install command with the `-e` flag for editable installation

```python
subprocess.check_call(
    [sys.executable, "-m", "pip", "install", "-e", *packages] # add -e flag to install in editable mode
)
```

### Step 2 — Test Installation and Rebuild Care

```bash
python install_plugins.py
```

if the above command installs the plugin successfully, run:

```bash
make re-build up
```

Care will install the plugin during image build. Your plugin's URLs will be available at `/api/{{ cookiecutter.plugin_slug }}/`.

Making a GET request to `/api/{{ cookiecutter.plugin_slug }}/hello` after login should return:

```json
{
    "message": "Hello from {{ cookiecutter.plugin_slug }}"
}
```

---

## 3. Apply Migrations

Every time you add or modify models in your plugin:

```bash
docker compose exec care python manage.py makemigrations {{ cookiecutter.plugin_slug }}
docker compose exec care python manage.py migrate
```

---

## 4. Run Tests

```bash
# From the Care repo root
make test
```

To run only your plugin's tests:

```bash
docker compose exec care python manage.py test {{ cookiecutter.plugin_slug }}
```

---

## 5. Iterate

| Action | Command |
| --- | --- |
| Start Care | `make up` |
| Stop Care | `make down` |
| Rebuild Care | `make re-build up` |
| View logs | `docker compose logs -f care` |
| Open shell | `docker compose exec care bash` |
| Load fixtures | `make load-fixtures` |
| Run migrations | `docker compose exec care python manage.py migrate` |
