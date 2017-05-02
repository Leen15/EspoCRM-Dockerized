# ESPOCRM in Docker

This is an unofficial dockerized version of [EspoCRM](https://www.espocrm.com/).   

It doesn't have custom settings, just attach a mysql container and launch it.   
If you want, you can use docker-compose with this command:   

    docker-compose -f docker-compose.yml up

   
and go to `http://localhost:8888/install` for the initial wizard.   
   
This image uses EspoCRM version **`4.6.0`**.      
   
If you need another version, just change `ESPO_VERSION` env and build a new image.   
