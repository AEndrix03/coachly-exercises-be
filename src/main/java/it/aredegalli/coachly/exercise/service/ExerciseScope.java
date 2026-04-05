package it.aredegalli.coachly.exercise.service;

import java.util.Locale;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

enum ExerciseScope {
    DEFAULT,
    MINE,
    COMMUNITY;

    static ExerciseScope parse(String rawValue) {
        if (rawValue == null || rawValue.isBlank()) {
            return DEFAULT;
        }

        String normalized = rawValue.trim().toUpperCase(Locale.ROOT);
        try {
            return ExerciseScope.valueOf(normalized);
        } catch (IllegalArgumentException ex) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invalid exercise scope");
        }
    }
}

