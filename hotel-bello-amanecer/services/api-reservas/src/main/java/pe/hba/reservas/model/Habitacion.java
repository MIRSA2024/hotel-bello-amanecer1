package pe.hba.reservas.model;

import jakarta.persistence.*;
import java.math.BigDecimal;

@Entity
@Table(name = "habitaciones")
public class Habitacion {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true, length = 10)
    private String numero;

    /** SIMPLE, DOBLE o SUITE */
    @Column(nullable = false, length = 20)
    private String tipo;

    @Column(nullable = false)
    private int capacidad;

    @Column(name = "precio_noche", nullable = false, precision = 10, scale = 2)
    private BigDecimal precioNoche;

    protected Habitacion() { }

    public Habitacion(String numero, String tipo, int capacidad, BigDecimal precioNoche) {
        this.numero = numero;
        this.tipo = tipo;
        this.capacidad = capacidad;
        this.precioNoche = precioNoche;
    }

    public Long getId() { return id; }
    public String getNumero() { return numero; }
    public String getTipo() { return tipo; }
    public int getCapacidad() { return capacidad; }
    public BigDecimal getPrecioNoche() { return precioNoche; }
}
