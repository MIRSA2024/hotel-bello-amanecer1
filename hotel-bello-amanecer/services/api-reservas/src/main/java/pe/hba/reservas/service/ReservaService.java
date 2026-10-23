package pe.hba.reservas.service;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.NoSuchElementException;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import pe.hba.reservas.model.EstadoReserva;
import pe.hba.reservas.model.Habitacion;
import pe.hba.reservas.model.Reserva;
import pe.hba.reservas.repo.HabitacionRepository;
import pe.hba.reservas.repo.ReservaRepository;

@Service
public class ReservaService {

    private final HabitacionRepository habitaciones;
    private final ReservaRepository reservas;
    private final ReservaEventPublisher publisher;

    public ReservaService(HabitacionRepository habitaciones, ReservaRepository reservas,
                          ReservaEventPublisher publisher) {
        this.habitaciones = habitaciones;
        this.reservas = reservas;
        this.publisher = publisher;
    }

    /** RF01: consulta de disponibilidad por fechas, tipo y número de huéspedes. */
    @Transactional(readOnly = true)
    public List<Habitacion> disponibles(LocalDate entrada, LocalDate salida, String tipo, int huespedes) {
        validarFechas(entrada, salida);
        if (tipo == null || tipo.isBlank()) {
            return habitaciones.disponibles(entrada, salida, huespedes, EstadoReserva.RECHAZADA);
        }
        return habitaciones.disponiblesPorTipo(entrada, salida, huespedes,
                tipo.trim().toUpperCase(), EstadoReserva.RECHAZADA);
    }

    /**
     * RF02 y RF03: registra la reserva en estado PENDIENTE y publica RESERVA_CREADA.
     * Si la publicación falla, la transacción se revierte (no queda una reserva sin evento).
     */
    @Transactional
    public Reserva crear(Long habitacionId, String nombre, String email,
                         LocalDate entrada, LocalDate salida, int huespedes) {
        validarFechas(entrada, salida);
        Habitacion hab = habitaciones.findById(habitacionId)
                .orElseThrow(() -> new NoSuchElementException("La habitación no existe"));
        if (huespedes > hab.getCapacidad()) {
            throw new IllegalArgumentException("La habitación admite hasta " + hab.getCapacidad() + " huéspedes");
        }
        if (reservas.haySolapamiento(habitacionId, entrada, salida, EstadoReserva.RECHAZADA)) {
            throw new IllegalStateException("La habitación no está disponible en esas fechas");
        }
        long noches = ChronoUnit.DAYS.between(entrada, salida);
        BigDecimal total = hab.getPrecioNoche().multiply(BigDecimal.valueOf(noches));
        Reserva reserva = reservas.saveAndFlush(
                new Reserva(habitacionId, nombre, email, entrada, salida, huespedes, total));
        publisher.publicarReservaCreada(reserva);
        return reserva;
    }

    /** RF06: consulta del estado de una reserva. */
    @Transactional(readOnly = true)
    public Reserva obtener(UUID id) {
        return reservas.findById(id).orElseThrow(() -> new NoSuchElementException("Reserva no encontrada"));
    }

    private void validarFechas(LocalDate entrada, LocalDate salida) {
        if (entrada == null || salida == null || !salida.isAfter(entrada)) {
            throw new IllegalArgumentException("La fecha de salida debe ser posterior a la de entrada");
        }
        if (entrada.isBefore(LocalDate.now().minusDays(1))) {
            throw new IllegalArgumentException("La fecha de entrada no puede estar en el pasado");
        }
    }
}
