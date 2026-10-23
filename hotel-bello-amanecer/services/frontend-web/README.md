# frontend-web (Angular 18)

Interfaz web del Hotel Bello Amanecer: consulta de disponibilidad, reserva y consulta de estado.

- Desarrollo local sin Docker: `npm install` y `npm start` (http://localhost:4200). La API debe estar en el puerto 8080.
- Producción: `npm run build -- --configuration production` (salida en `dist/hotel-web/browser`).
- En AWS el ALB enruta `/api/*` hacia la API; en local con Compose el frontend (8081) llama a `http://localhost:8080/api`.
