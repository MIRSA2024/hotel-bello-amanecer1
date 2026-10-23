package pe.hba.reservas.web;

import jakarta.validation.Valid;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import pe.hba.reservas.model.Habitacion;
import pe.hba.reservas.model.Reserva;
import pe.hba.reservas.service.ReservaService;

@RestController
@RequestMapping("/api")
public class ReservaController {

    public record HabitacionDto(Long id, String numero, String tipo, int capacidad, BigDecimal precioNoche) {
        static HabitacionDto de(Habitacion h) {
            return new HabitacionDto(h.getId(), h.getNumero(), h.getTipo(), h.getCapacidad(), h.getPrecioNoche());
        }
    }

    public record NuevaReserva(
            @NotNull Long habitacionId,
            @NotBlank String nombre,
            @NotBlank @Email String email,
            @NotNull LocalDate fechaEntrada,
            @NotNull LocalDate fechaSalida,
            @Min(1) @Max(10) int huespedes) { }

    public record ReservaDto(UUID id, Long habitacionId, String nombre, String email, LocalDate fechaEntrada,
                             LocalDate fechaSalida, int huespedes, BigDecimal total, String estado, Instant creadaEn) {
        static ReservaDto de(Reserva r) {
            return new ReservaDto(r.getId(), r.getHabitacionId(), r.getHuespedNombre(), r.getHuespedEmail(),
                    r.getFechaEntrada(), r.getFechaSalida(), r.getNumHuespedes(), r.getTotal(),
                    r.getEstado().name(), r.getCreadaEn());
        }
    }

    private final ReservaService service;

    public ReservaController(ReservaService service) {
        this.service = service;
    }

    @GetMapping("/habitaciones/disponibles")
    public List<HabitacionDto> disponibles(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate entrada,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate salida,
            @RequestParam(required = false) String tipo,
            @RequestParam(defaultValue = "1") int huespedes) {
        return service.disponibles(entrada, salida, tipo, huespedes).stream().map(HabitacionDto::de).toList();
    }

    @PostMapping("/reservas")
    @ResponseStatus(HttpStatus.CREATED)
    public ReservaDto crear(@Valid @RequestBody NuevaReserva body) {
        return ReservaDto.de(service.crear(body.habitacionId(), body.nombre(), body.email(),
                body.fechaEntrada(), body.fechaSalida(), body.huespedes()));
    }

    @GetMapping("/reservas/{id}")
    public ReservaDto obtener(@PathVariable UUID id) {
        return ReservaDto.de(service.obtener(id));
    }
}
