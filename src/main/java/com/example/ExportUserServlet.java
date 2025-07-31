package com.example;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.List;
import java.util.Map;

@WebServlet("/users/export")
public class ExportUserServlet extends HttpServlet {
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        resp.setContentType("text/csv;charset=UTF-8");
        resp.setHeader("Content-Disposition", "attachment; filename=benutzer_export.csv");
        PrintWriter out = resp.getWriter();
        // Header wie Importdatei
        out.println("Mitarbeiterkennung;Name;Vorname;Abteilung;Team;Stelle;aktiv;ist Benutzer;Benutzerverwaltung;Feiertage verwalten;Logbuch");
        try {
            List<Map<String, Object>> users = DatabaseService.getAllUsers();
            for (Map<String, Object> u : users) {
                String line = String.join(";",
                    safe(u.get("username")),
                    safe(u.get("name")),
                    safe(u.get("vorname")),
                    safe(u.get("abteilung")),
                    safe(u.get("team")),
                    safe(u.get("stelle")),
                    boolToCsv(u.get("active")),
                    boolToCsv(u.get("is_user")),
                    boolToCsv(u.get("can_manage_users")),
                    boolToCsv(u.get("can_manage_feiertage")),
                    boolToCsv(u.get("can_view_logbook"))
                );
                out.println(line);
            }
        } catch (Exception e) {
            out.println("Fehler beim Export: " + e.getMessage());
        }
    }

    private String safe(Object o) {
        return o == null ? "" : o.toString().replace(";", ",");
    }
    private String boolToCsv(Object o) {
        if (o == null) return "0";
        if (o instanceof Boolean) return ((Boolean)o) ? "1" : "0";
        return "0";
    }
}
