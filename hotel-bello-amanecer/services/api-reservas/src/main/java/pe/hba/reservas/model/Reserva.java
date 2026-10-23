package pe.hba.reservas.model;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

@Entity
@Table(name = "reservas")
public class Reserva {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "habitacion_id", nullable = false)
    private Long habitacionId;

    @Column(name = "huesped_nombre", nullable = false, length = 120)
    private String huespedNombre;

    @Column(name = "huesped_email", nullable = false, length = 160)
    private String huespedEmail;

    @Column(name = "fecha_entrada", nullable = false)
    private LocalDate fechaEntrada;

    @Column(name = "fecha_salida", nullable = false)
    private LocalDate fechaSalida;

    @Column(name = "num_huespedes", nullable = false)
    private int numHuespedes;

    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal total;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private EstadoReserva estado = EstadoReserva.PENDIENTE;

    @Column(name = "creada_en", nullable = false)
    private Instant creadaEn = Instant.now();

    protected Reserva() { }

    public Reserva(Long habitacionId, String huespedNombre, String huespedEmail,
                   LocalDate fechaEntrada, LocalDate fechaSalida, int numHuespedes, BigDecimal total) {
        this.habitacionId = habitacionId;
        this.huespedNombre = huespedNombre;
        this.huespedEmail = huespedEmail;
        this.fechaEntrada = fechaEntrada;
        this.fechaSalida = fechaSalida;
        this.numHuespedes = numHuespedes;
        this.total = total;
    }

    public UUID getId() { return id; }
    public Long getHabitacionId() { return habitacionId; }
    public String getHuespedNombre() { return huespedNombre; }
    public String getHuespedEmail() { return huespedEmail; }
    public LocalDate getFechaEntrada() { return fechaEntrada; }
    public LocalDate getFechaSalida() { return fechaSalida; }
    public int getNumHuespedes() { return numHuespedes; }
    public BigDecimal getTotal() { return total; }
    public EstadoReserva getEstado() { return estado; }
    public Instant getCreadaEn() { return creadaEn; }
}
