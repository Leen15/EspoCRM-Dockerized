# ESPOCRM in Docker

This is an unofficial dockerized version of [EspoCRM](https://www.espocrm.com/).

It doesn't have custom settings, just attach a mysql container and launch it.
If you want, you can use docker-compose with this command:

    docker-compose -f docker-compose.yml up


and go to `http://localhost:8888/install` for the initial wizard.

This image uses Ubuntu `18.04`, PHP `7.2` and EspoCRM version **`5.9.4`**.

If you need another version, just change `ESPO_VERSION` env and build a new image.

It is important to mount a volume into the container at /var/www/data, otherwise
configuration and uploads will be lost following a container restart.
