package com.example;

import java.sql.Timestamp;
import java.time.Instant;

public class LogEintrag {

    private int id;
    private Timestamp timestamp;
    private String aktion;
    private String beschreibung;

    // Nur DIESER Konstruktor wird benötigt
    public LogEintrag(String aktion, String beschreibung) {
        this.timestamp = Timestamp.from(Instant.now());
        this.aktion = aktion;
        this.beschreibung = beschreibung;
    }
    
    // Getter und Setter bleiben unverändert...
    public int getId() { return id; }
    public void setId(int id) { this.id = id; }
    public Timestamp getTimestamp() { return timestamp; }
    public void setTimestamp(Timestamp timestamp) { this.timestamp = timestamp; }
    public String getAktion() { return aktion; }
    public void setAktion(String aktion) { this.aktion = aktion; }
    public String getBeschreibung() { return beschreibung; }
    public void setBeschreibung(String beschreibung) { this.beschreibung = beschreibung; }
}