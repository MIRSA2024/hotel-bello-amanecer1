package pe.hba.reservas.repo;

import java.time.LocalDate;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import pe.hba.reservas.model.EstadoReserva;
import pe.hba.reservas.model.Habitacion;

public interface HabitacionRepository extends JpaRepository<Habitacion, Long> {

    String LIBRE = """
            not exists (select r.id from Reserva r
                        where r.habitacionId = h.id
                          and r.estado <> :rechazada
                          and r.fechaEntrada < :salida
                          and r.fechaSalida > :entrada)
            """;

    @Query("select h from Habitacion h where h.capacidad >= :huespedes and " + LIBRE + " order by h.precioNoche")
    List<Habitacion> disponibles(@Param("entrada") LocalDate entrada,
                                 @Param("salida") LocalDate salida,
                                 @Param("huespedes") int huespedes,
                                 @Param("rechazada") EstadoReserva rechazada);

    @Query("select h from Habitacion h where h.tipo = :tipo and h.capacidad >= :huespedes and " + LIBRE + " order by h.precioNoche")
    List<Habitacion> disponiblesPorTipo(@Param("entrada") LocalDate entrada,
                                        @Param("salida") LocalDate salida,
                                        @Param("huespedes") int huespedes,
                                        @Param("tipo") String tipo,
                                        @Param("rechazada") EstadoReserva rechazada);
}
