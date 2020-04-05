# addhttps
Adds letsencrypt certificate to an existing apache virtualhost

The script will add or modify an existing apache2 virtualhost file to user letsenrypt certificate

Requirenments:
- Linux server (testend on Debian)
- Apache2 web server
- Dehydrated for letsencrypt (more info: https://dehydrated.io/)
  can be installed with apt-get install dehydrated dehydrated-apache2 
