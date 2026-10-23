import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { HttpClient } from '@angular/common/http';

interface Habitacion { id: number; numero: string; tipo: string; capacidad: number; precioNoche: number; }
interface Reserva { id: string; habitacionId: number; nombre: string; email: string;
  fechaEntrada: string; fechaSalida: string; huespedes: number; total: number; estado: string; }

/** En AWS el ALB enruta /api/* a la API. En local el frontend (8081) llama a la API en el puerto 8080. */
const API = window.location.port === '8081' ? `${window.location.protocol}//${window.location.hostname}:8080/api` : '/api';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './app.component.html',
  styleUrl: './app.component.css'
})
export class AppComponent {
  hoy = new Date().toISOString().slice(0, 10);
  busqueda = { entrada: this.hoy, salida: this.hoy, tipo: '', huespedes: 2 };
  habitaciones: Habitacion[] = [];
  buscado = false;

  seleccionada?: Habitacion;
  huesped = { nombre: '', email: '' };
  reserva?: Reserva;

  consultaId = '';
  consulta?: Reserva;

  mensaje = '';
  error = '';

  constructor(private http: HttpClient) {}

  buscar(): void {
    this.limpiar();
    const q = `entrada=${this.busqueda.entrada}&salida=${this.busqueda.salida}` +
      `&huespedes=${this.busqueda.huespedes}` + (this.busqueda.tipo ? `&tipo=${this.busqueda.tipo}` : '');
    this.http.get<Habitacion[]>(`${API}/habitaciones/disponibles?${q}`).subscribe({
      next: h => { this.habitaciones = h; this.buscado = true; this.seleccionada = undefined; },
      error: e => this.error = e.error?.error ?? 'No se pudo consultar la disponibilidad'
    });
  }

  elegir(h: Habitacion): void { this.seleccionada = h; this.reserva = undefined; }

  reservar(): void {
    if (!this.seleccionada) { return; }
    this.limpiar();
    this.http.post<Reserva>(`${API}/reservas`, {
      habitacionId: this.seleccionada.id,
      nombre: this.huesped.nombre,
      email: this.huesped.email,
      fechaEntrada: this.busqueda.entrada,
      fechaSalida: this.busqueda.salida,
      huespedes: this.busqueda.huespedes
    }).subscribe({
      next: r => { this.reserva = r; this.consultaId = r.id; this.mensaje = 'Reserva registrada. Estado inicial: PENDIENTE.'; },
      error: e => this.error = e.error?.error ?? 'No se pudo registrar la reserva'
    });
  }

  consultar(): void {
    this.limpiar();
    this.http.get<Reserva>(`${API}/reservas/${this.consultaId.trim()}`).subscribe({
      next: r => this.consulta = r,
      error: e => this.error = e.error?.error ?? 'Reserva no encontrada'
    });
  }

  private limpiar(): void { this.mensaje = ''; this.error = ''; }
}
