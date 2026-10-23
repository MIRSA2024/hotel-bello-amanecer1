package pe.hba.reservas.config;

import java.math.BigDecimal;
import java.net.URI;
import java.util.List;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;
import pe.hba.reservas.model.Habitacion;
import pe.hba.reservas.repo.HabitacionRepository;
import software.amazon.awssdk.auth.credentials.AwsBasicCredentials;
import software.amazon.awssdk.auth.credentials.StaticCredentialsProvider;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.sqs.SqsClient;
import software.amazon.awssdk.services.sqs.SqsClientBuilder;

@Configuration
public class AppConfig {

    /**
     * Cliente SQS. En AWS usa las credenciales del rol de la tarea (cadena por defecto);
     * en local apunta al emulador ElasticMQ mediante SQS_ENDPOINT.
     */
    @Bean
    SqsClient sqsClient(@Value("${app.sqs-endpoint:}") String endpoint,
                        @Value("${app.aws-region}") String region) {
        SqsClientBuilder builder = SqsClient.builder().region(Region.of(region));
        if (!endpoint.isBlank()) {
            builder.endpointOverride(URI.create(endpoint))
                   .credentialsProvider(StaticCredentialsProvider.create(
                           AwsBasicCredentials.create("local", "local")));
        }
        return builder.build();
    }

    /** Permite que el frontend (otro puerto en local) consuma la API. */
    @Bean
    WebMvcConfigurer cors() {
        return new WebMvcConfigurer() {
            @Override
            public void addCorsMappings(CorsRegistry registry) {
                registry.addMapping("/api/**").allowedOriginPatterns("*").allowedMethods("GET", "POST");
            }
        };
    }

    /** Carga inicial de habitaciones de prueba (solo si la tabla está vacía). */
    @Bean
    CommandLineRunner cargarHabitaciones(HabitacionRepository repo) {
        return args -> {
            if (repo.count() > 0) {
                return;
            }
            repo.saveAll(List.of(
                    new Habitacion("101", "SIMPLE", 1, new BigDecimal("120.00")),
                    new Habitacion("102", "SIMPLE", 1, new BigDecimal("120.00")),
                    new Habitacion("103", "SIMPLE", 2, new BigDecimal("140.00")),
                    new Habitacion("201", "DOBLE", 2, new BigDecimal("200.00")),
                    new Habitacion("202", "DOBLE", 2, new BigDecimal("200.00")),
                    new Habitacion("203", "DOBLE", 3, new BigDecimal("240.00")),
                    new Habitacion("204", "DOBLE", 4, new BigDecimal("280.00")),
                    new Habitacion("301", "SUITE", 2, new BigDecimal("380.00")),
                    new Habitacion("302", "SUITE", 4, new BigDecimal("520.00"))));
        };
    }
}
