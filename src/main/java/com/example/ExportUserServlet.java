package com.example;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession; // KORREKTUR: Fehlender Import
import java.io.IOException;
import java.io.PrintWriter;
import java.util.List;
import java.util.Map;

@WebServlet("/users/export")
public class ExportUserServlet extends HttpServlet {
    @Override
    @SuppressWarnings("unchecked")
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        resp.setContentType("text/csv;charset=UTF-8");
        resp.setHeader("Content-Disposition", "attachment; filename=benutzer_export.csv");
        
        HttpSession session = req.getSession(false);
        Map<String, Object> currentUser = (session != null) ? (Map<String, Object>) session.getAttribute("user") : null;

        try (PrintWriter out = resp.getWriter()) {
            out.println("Mitarbeiterkennung;Name;Vorname;Abteilung;Team;Stelle;aktiv;ist Benutzer;Benutzerverwaltung;Logbuch;Feiertage verwalten;Alle Benutzer sehen");
            
            List<Map<String, Object>> users = DatabaseService.getAllUsers(currentUser);
            
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
                    boolToCsv(u.get("can_view_logbook")),
                    boolToCsv(u.get("can_manage_feiertage")),
                    boolToCsv(u.get("see_all_users")),
                    boolToCsv(u.get("can_manage_calendar")),
                    boolToCsv(u.get("can_manage_capacities")),
                    boolToCsv(u.get("can_manage_settings")),
                    boolToCsv(u.get("can_manage_tasks")),
                    boolToCsv(u.get("can_manage_calendar_overview"))
                );
                out.println(line);
            }
        } catch (Exception e) {
            resp.getWriter().println("Fehler beim Export: " + e.getMessage());
        }
    }

    private String safe(Object o) {
        return o == null ? "" : o.toString().replace(";", ",");
    }

    private String boolToCsv(Object o) {
        if (Boolean.TRUE.equals(o)) {
            return "1";
        }
        return "0";
    }
}