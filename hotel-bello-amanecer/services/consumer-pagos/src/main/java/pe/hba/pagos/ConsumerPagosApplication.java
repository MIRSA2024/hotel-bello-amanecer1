package pe.hba.pagos;

import java.net.URI;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.scheduling.annotation.EnableScheduling;
import software.amazon.awssdk.auth.credentials.AwsBasicCredentials;
import software.amazon.awssdk.auth.credentials.StaticCredentialsProvider;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.sqs.SqsClient;
import software.amazon.awssdk.services.sqs.SqsClientBuilder;

@SpringBootApplication
@EnableScheduling
public class ConsumerPagosApplication {

    public static void main(String[] args) {
        SpringApplication.run(ConsumerPagosApplication.class, args);
    }

    /** En AWS usa el rol de la tarea; en local apunta a ElasticMQ (SQS_ENDPOINT). */
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
}
