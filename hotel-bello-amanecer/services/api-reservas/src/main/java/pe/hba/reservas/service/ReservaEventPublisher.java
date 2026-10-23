package pe.hba.reservas.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import pe.hba.reservas.model.Reserva;
import software.amazon.awssdk.services.sqs.SqsClient;
import software.amazon.awssdk.services.sqs.model.GetQueueUrlRequest;
import software.amazon.awssdk.services.sqs.model.SendMessageRequest;

/** Publica el evento RESERVA_CREADA en la cola q-reservas (RF03). */
@Component
public class ReservaEventPublisher {

    private final SqsClient sqs;
    private final ObjectMapper mapper;
    private final String queueName;
    private volatile String queueUrl;

    public ReservaEventPublisher(SqsClient sqs, ObjectMapper mapper,
                                 @Value("${app.sqs-queue-reservas}") String queueName) {
        this.sqs = sqs;
        this.mapper = mapper;
        this.queueName = queueName;
    }

    public void publicarReservaCreada(Reserva reserva) {
        Map<String, Object> evento = new LinkedHashMap<>();
        evento.put("evento", "RESERVA_CREADA");
        evento.put("reserva_id", reserva.getId().toString());
        evento.put("huesped_nombre", reserva.getHuespedNombre());
        evento.put("huesped_email", reserva.getHuespedEmail());
        evento.put("total", reserva.getTotal());
        evento.put("ocurrio_en", Instant.now().toString());
        try {
            sqs.sendMessage(SendMessageRequest.builder()
                    .queueUrl(resolverUrl())
                    .messageBody(mapper.writeValueAsString(evento))
                    .build());
        } catch (JsonProcessingException e) {
            throw new IllegalStateException("No se pudo serializar el evento", e);
        }
    }

    private String resolverUrl() {
        if (queueUrl == null) {
            queueUrl = sqs.getQueueUrl(GetQueueUrlRequest.builder().queueName(queueName).build()).queueUrl();
        }
        return queueUrl;
    }
}
