package pe.hba.notificaciones;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.List;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import software.amazon.awssdk.services.sqs.SqsClient;
import software.amazon.awssdk.services.sqs.model.DeleteMessageRequest;
import software.amazon.awssdk.services.sqs.model.GetQueueUrlRequest;
import software.amazon.awssdk.services.sqs.model.Message;
import software.amazon.awssdk.services.sqs.model.ReceiveMessageRequest;

/**
 * Consume RESERVA_CONFIRMADA de q-notificaciones y envía el comprobante por correo (RF05).
 * MAIL_PROVIDER=log solo registra el correo; MAIL_PROVIDER=sendgrid lo envía con la API de SendGrid.
 */
@Component
public class NotificacionWorker {

    private static final Logger log = LoggerFactory.getLogger(NotificacionWorker.class);

    private final SqsClient sqs;
    private final ObjectMapper mapper;
    private final String cola;
    private final String proveedor;
    private final String remitente;
    private final String apiKey;
    private final HttpClient http = HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(5)).build();
    private String url;

    public NotificacionWorker(SqsClient sqs, ObjectMapper mapper,
                              @Value("${app.sqs-queue-entrada}") String cola,
                              @Value("${app.mail-provider}") String proveedor,
                              @Value("${app.mail-from}") String remitente,
                              @Value("${app.mail-api-key}") String apiKey) {
        this.sqs = sqs;
        this.mapper = mapper;
        this.cola = cola;
        this.proveedor = proveedor;
        this.remitente = remitente;
        this.apiKey = apiKey;
    }

    @Scheduled(fixedDelay = 500)
    public void sondear() {
        try {
            if (url == null) {
                url = sqs.getQueueUrl(GetQueueUrlRequest.builder().queueName(cola).build()).queueUrl();
                log.info("Escuchando la cola {} (proveedor de correo: {})", cola, proveedor);
            }
            var respuesta = sqs.receiveMessage(ReceiveMessageRequest.builder()
                    .queueUrl(url).maxNumberOfMessages(5).waitTimeSeconds(10).build());
            for (Message m : respuesta.messages()) {
                try {
                    enviar(mapper.readTree(m.body()));
                    sqs.deleteMessage(DeleteMessageRequest.builder()
                            .queueUrl(url).receiptHandle(m.receiptHandle()).build());
                } catch (Exception e) {
                    log.error("Error al notificar el mensaje {} (se reintentará): {}", m.messageId(), e.toString());
                }
            }
        } catch (Exception e) {
            log.warn("Cola no disponible todavía: {}", e.toString());
            url = null;
            try {
                Thread.sleep(3000);
            } catch (InterruptedException ie) {
                Thread.currentThread().interrupt();
            }
        }
    }

    private void enviar(JsonNode evento) throws Exception {
        String para = evento.get("huesped_email").asText();
        String nombre = evento.get("huesped_nombre").asText();
        String asunto = "Reserva confirmada - Hotel Bello Amanecer";
        String texto = "Hola " + nombre + ", tu reserva " + evento.get("reserva_id").asText()
                + " fue confirmada. Total: S/ " + evento.get("total").asText() + ".";

        if (!"sendgrid".equalsIgnoreCase(proveedor)) {
            log.info("[CORREO SIMULADO] para={} asunto='{}' cuerpo='{}'", para, asunto, texto);
            return;
        }
        String json = mapper.writeValueAsString(Map.of(
                "personalizations", List.of(Map.of("to", List.of(Map.of("email", para)))),
                "from", Map.of("email", remitente),
                "subject", asunto,
                "content", List.of(Map.of("type", "text/plain", "value", texto))));
        HttpRequest req = HttpRequest.newBuilder(URI.create("https://api.sendgrid.com/v3/mail/send"))
                .timeout(Duration.ofSeconds(10))
                .header("Authorization", "Bearer " + apiKey)
                .header("Content-Type", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString(json)).build();
        HttpResponse<String> resp = http.send(req, HttpResponse.BodyHandlers.ofString());
        if (resp.statusCode() >= 300) {
            throw new IllegalStateException("SendGrid respondió " + resp.statusCode());
        }
        log.info("Correo enviado a {}", para);
    }
}
