package pe.hba.reservas.repo;

import java.time.LocalDate;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import pe.hba.reservas.model.EstadoReserva;
import pe.hba.reservas.model.Reserva;

public interface ReservaRepository extends JpaRepository<Reserva, UUID> {

    @Query("""
            select count(r) > 0 from Reserva r
            where r.habitacionId = :habitacionId
              and r.estado <> :rechazada
              and r.fechaEntrada < :salida
              and r.fechaSalida > :entrada
            """)
    boolean haySolapamiento(@Param("habitacionId") Long habitacionId,
                            @Param("entrada") LocalDate entrada,
                            @Param("salida") LocalDate salida,
                            @Param("rechazada") EstadoReserva rechazada);
}
