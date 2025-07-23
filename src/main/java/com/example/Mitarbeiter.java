package com.example;

public class Mitarbeiter {

    private int id;
    private String name;
    private String stelle;
    private String team;
    private String abteilung;

    // Standard-Konstruktor (wichtig für manche Frameworks)
    public Mitarbeiter() {
    }
    
    // **NEUER, KORRIGIERTER KONSTRUKTOR**
    // Dieser wird vom AddMitarbeiterServlet verwendet.
    public Mitarbeiter(String name, String stelle, String team, String abteilung) {
        this.name = name;
        this.stelle = stelle;
        this.team = team;
        this.abteilung = abteilung;
    }

    // Dieser Konstruktor wird zum Einlesen aus der Datenbank verwendet.
    public Mitarbeiter(int id, String name, String stelle, String team, String abteilung) {
        this.id = id;
        this.name = name;
        this.stelle = stelle;
        this.team = team;
        this.abteilung = abteilung;
    }

    // Getter und Setter
    public int getId() { return id; }
    public void setId(int id) { this.id = id; }
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public String getStelle() { return stelle; }
    public void setStelle(String stelle) { this.stelle = stelle; }
    public String getTeam() { return team; }
    public void setTeam(String team) { this.team = team; }
    public String getAbteilung() { return abteilung; }
    public void setAbteilung(String abteilung) { this.abteilung = abteilung; }
}