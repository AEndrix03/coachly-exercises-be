package it.aredegalli.coachly.exercise;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication(scanBasePackages = "it.aredegalli.coachly")
@EnableScheduling
public class CoachlyExercisesBeApplication {

	public static void main(String[] args) {
		SpringApplication.run(CoachlyExercisesBeApplication.class, args);
	}

}
