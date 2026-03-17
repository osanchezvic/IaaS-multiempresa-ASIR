services:
  grafana:
    container_name: {{EMPRESA}}_grafana
    image: grafana/grafana:latest
    restart: always
    environment:
      - GF_SECURITY_ADMIN_USER={{ADMIN_USER}}
      - GF_SECURITY_ADMIN_PASSWORD={{ADMIN_PASSWORD}}
    volumes:
      - {{RUTA_DATOS}}/grafana:/var/lib/grafana
    networks:
      - {{EMPRESA}}_net
    ports:
      - "{{PUERTO}}:3000"

networks:
  {{EMPRESA}}_net:
    external: true
