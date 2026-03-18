services:
  {{EMPRESA}}_mariadb:
    image: mariadb:latest
    container_name: {{EMPRESA}}_mariadb
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: {{DB_PASSWORD}}
      MYSQL_DATABASE: {{DB_NAME}}
      MYSQL_USER: {{DB_USER}}
      MYSQL_PASSWORD: {{DB_PASSWORD}}
    volumes:
      - {{RUTA_DATOS}}/mariadb:/var/lib/mysql
    networks:
      - {{EMPRESA}}_net

  {{EMPRESA}}_wordpress:
    image: wordpress:latest
    container_name: {{EMPRESA}}_wordpress
    restart: always
    depends_on:
      - {{EMPRESA}}_mariadb
    environment:
      WORDPRESS_DB_HOST: {{EMPRESA}}_mariadb
      WORDPRESS_DB_USER: {{DB_USER}}
      WORDPRESS_DB_PASSWORD: {{DB_PASSWORD}}
      WORDPRESS_DB_NAME: {{DB_NAME}}
    ports:
      - "{{PUERTO}}:80"
    volumes:
      - {{RUTA_DATOS}}/wordpress:/var/www/html
    networks:
      - {{EMPRESA}}_net

networks:
  {{EMPRESA}}_net:
    external: true
