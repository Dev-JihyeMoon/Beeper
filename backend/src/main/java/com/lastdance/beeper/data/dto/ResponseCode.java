package com.lastdance.beeper.data.dto;

public enum ResponseCode {
    SUCCESS,
    FAILURE,
    UNAUTHORIZED;


    @Override
    public String toString() {
        return super.name();
    }
}
