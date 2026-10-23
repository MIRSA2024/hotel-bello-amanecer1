package pe.hba.pagos;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ThreadLocalRandom;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import software.amazon.awssdk.services.sqs.SqsClient;
import software.amazon.awssdk.services.sqs.model.DeleteMessageRequest;
import software.amazon.awssdk.services.sqs.model.GetQueueUrlRequest;
import software.amazon.awssdk.services.sqs.model.Message;
import software.amazon.awssdk.services.sqs.model.ReceiveMessageRequest;
import software.amazon.awssdk.services.sqs.model.SendMessageRequest;

/**
 * Consume RESERVA_CREADA de q-reservas, simula el pago, actualiza la reserva (RF04)
 * y publica RESERVA_CONFIRMADA en q-notificaciones. Es idempotente: una reserva que
 * ya no está PENDIENTE no se procesa dos veces.
 * Si ocurre un error el mensaje NO se borra: SQS lo reentrega y tras 5 intentos pasa a la DLQ.
 */
@Component
public class PagoWorker {

    private static final Logger log = LoggerFactory.getLogger(PagoWorker.class);

    private final SqsClient sqs;
    private final JdbcTemplate jdbc;
    private final ObjectMapper mapper;
    private final String colaEntrada;
    private final String colaSalida;
    private final long latenciaMs;
    private final double tasaRechazo;
    private final boolean forzarError;
    private String urlEntrada;
    private String urlSalida;

    public PagoWorker(SqsClient sqs, JdbcTemplate jdbc, ObjectMapper mapper,
                      @Value("${app.sqs-queue-entrada}") String colaEntrada,
                      @Value("${app.sqs-queue-salida}") String colaSalida,
                      @Value("${app.pago-latencia-ms}") long latenciaMs,
                      @Value("${app.pago-tasa-rechazo}") double tasaRechazo,
                      @Value("${app.pago-forzar-error}") boolean forzarError) {
        this.sqs = sqs;
        this.jdbc = jdbc;
        this.mapper = mapper;
        this.colaEntrada = colaEntrada;
        this.colaSalida = colaSalida;
        this.latenciaMs = latenciaMs;
        this.tasaRechazo = tasaRechazo;
        this.forzarError = forzarError;
    }

    @Scheduled(fixedDelay = 500)
    public void sondear() {
        try {
            if (urlEntrada == null) {
                urlEntrada = urlDe(colaEntrada);
                urlSalida = urlDe(colaSalida);
                log.info("Escuchando la cola {}", colaEntrada);
            }
            var respuesta = sqs.receiveMessage(ReceiveMessageRequest.builder()
                    .queueUrl(urlEntrada).maxNumberOfMessages(5).waitTimeSeconds(10).build());
            for (Message m : respuesta.messages()) {
                try {
                    procesar(m);
                    sqs.deleteMessage(DeleteMessageRequest.builder()
                            .queueUrl(urlEntrada).receiptHandle(m.receiptHandle()).build());
                } catch (Exception e) {
                    log.error("Error al procesar el mensaje {} (se reintentará): {}", m.messageId(), e.toString());
                }
            }
        } catch (Exception e) {
            log.warn("Cola no disponible todavía: {}", e.toString());
            urlEntrada = null;
            esperar(3000);
        }
    }

    private void procesar(Message m) throws Exception {
        if (forzarError) {
            throw new IllegalStateException("Error forzado para probar la DLQ");
        }
        JsonNode evento = mapper.readTree(m.body());
        UUID reservaId = UUID.fromString(evento.get("reserva_id").asText());

        esperar(latenciaMs); // latencia de la pasarela simulada
        boolean aprobado = ThreadLocalRandom.current().nextDouble() >= tasaRechazo;
        String nuevoEstado = aprobado ? "CONFIRMADA" : "RECHAZADA";

        int filas = jdbc.update("update reservas set estado = ? where id = ? and estado = 'PENDIENTE'",
                nuevoEstado, reservaId);
        if (filas == 0) {
            log.info("Reserva {} ya procesada; se ignora el mensaje duplicado", reservaId);
            return;
        }
        log.info("Reserva {} -> {}", reservaId, nuevoEstado);

        if (aprobado) {
            Map<String, Object> datos = jdbc.queryForMap(
                    "select huesped_nombre, huesped_email, total from reservas where id = ?", reservaId);
            Map<String, Object> salida = new LinkedHashMap<>();
            salida.put("evento", "RESERVA_CONFIRMADA");
            salida.put("reserva_id", reservaId.toString());
            salida.put("huesped_nombre", datos.get("huesped_nombre"));
            salida.put("huesped_email", datos.get("huesped_email"));
            salida.put("total", datos.get("total"));
            salida.put("ocurrio_en", Instant.now().toString());
            sqs.sendMessage(SendMessageRequest.builder()
                    .queueUrl(urlSalida).messageBody(toJson(salida)).build());
        }
    }

    private String toJson(Object o) {
        try {
            return mapper.writeValueAsString(o);
        } catch (Exception e) {
            throw new IllegalStateException(e);
        }
    }

    private String urlDe(String nombre) {
        return sqs.getQueueUrl(GetQueueUrlRequest.builder().queueName(nombre).build()).queueUrl();
    }

    private static void esperar(long ms) {
        try {
            Thread.sleep(ms);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }
}
