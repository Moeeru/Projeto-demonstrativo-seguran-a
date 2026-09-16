package com.demo.resiliencia.exception;

public class InjecaoDeFalhaException extends RuntimeException {
    public InjecaoDeFalhaException(String message) {
        super(message);
    }
}
