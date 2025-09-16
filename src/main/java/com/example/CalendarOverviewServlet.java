package com.example;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.google.gson.JsonSyntaxException;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.temporal.TemporalAdjusters;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

// WICHTIG: Die URL-Zuordnung muss flexibel sein, um Unterpfade zu erlauben
@WebServlet("/calendar-overview/*")
public class CalendarOverviewServlet extends HttpServlet {

    // GsonBuilder so konfigurieren, dass er LocalDate korrekt umwandelt
    private final Gson gson = new GsonBuilder()
            .registerTypeAdapter(LocalDate.class, new com.google.gson.JsonSerializer<LocalDate>() {
                @Override
                public com.google.gson.JsonElement serialize(LocalDate src, java.lang.reflect.Type typeOfSrc, com.google.gson.JsonSerializationContext context) {
                    return new com.google.gson.JsonPrimitive(src.format(DateTimeFormatter.ISO_LOCAL_DATE));
                }
            })
            .create();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String pathInfo = req.getPathInfo();

        // Fall 1: Der Request ist für die JSON-Daten (URL endet auf /data)
        if (pathInfo != null && pathInfo.equals("/data")) {
            handleDataRequest(req, resp);
        }
        // Fall 2: Der Request ist für die HTML-Seite
        else {
            handlePageRequest(req, resp);
        }
    }

    /**
     * Liefert die JSP-Seite aus.
     */
    private void handlePageRequest(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        req.getRequestDispatcher("/WEB-INF/calendar_overview.jsp").forward(req, resp);
    }

    /**
     * Holt die Daten aus der Datenbank und sendet sie als JSON.
     */

    private void handleDataRequest(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        resp.setContentType("application/json");
        resp.setCharacterEncoding("UTF-8");

        // Den aktuell angemeldeten Benutzer aus der Session holen
        HttpSession session = req.getSession(false);
        @SuppressWarnings("unchecked")
        Map<String, Object> currentUser = (session != null) ? (Map<String, Object>) session.getAttribute("user") : null;

        if (currentUser == null) {
            resp.setStatus(HttpServletResponse.SC_FORBIDDEN);
            try (PrintWriter out = resp.getWriter()) {
                out.print("{\"error\": \"Zugriff verweigert.\"}");
            }
            return;
        }

        // KORREKTUR: PrintWriter außerhalb des Haupt-try-Blocks deklarieren,
        // um im catch-Block darauf zugreifen zu können.
        try (PrintWriter out = resp.getWriter()) {
            try {
                int year = Integer.parseInt(req.getParameter("year"));
                int month = Integer.parseInt(req.getParameter("month"));

                Map<String, Object> responseData = new HashMap<>();
                responseData.put("days", getDaysOfMonth(year, month));
                responseData.put("departments", getAllUsersWithAbsencesAndDepartments(year, month, currentUser));
                responseData.put("colors", DatabaseService.getCalendarColors());

                String jsonResponse = gson.toJson(responseData);
                out.print(jsonResponse);

            } catch (Exception e) {
                resp.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
                // Sende eine gültige JSON-Fehlermeldung
                out.print("{\"error\": \"Serverfehler: " + e.getMessage().replace("\"", "'") + "\"}");
                e.printStackTrace(); // Wichtig für die Fehlersuche auf dem Server
            }
        } catch (IOException e) {
            // Fängt Fehler ab, falls resp.getWriter() fehlschlägt
            e.printStackTrace();
        }
    }

    /**
     * Stellt die Daten für die Kalenderübersicht zusammen.
     * Holt Benutzer, Abwesenheiten und Kapazitäten und führt sie zusammen.
     */
    private Map<String, List<Map<String, Object>>> getAllUsersWithAbsencesAndDepartments(int year, int month, Map<String, Object> currentUser) throws SQLException {
        LocalDate monthStart = LocalDate.of(year, month, 1);
        LocalDate monthEnd = monthStart.with(TemporalAdjusters.lastDayOfMonth());

        // Schritt 1: Hole die korrekt gefilterte Liste der Benutzer
        List<Map<String, Object>> visibleUsers = DatabaseService.getAllActiveUsers(currentUser);

        // Schritt 2: Hole ALLE Abwesenheiten, Kapazitäten und Aufgaben für den Zeitraum
        Map<Integer, List<String>> allAbsences = DatabaseService.getAbsencesForMonth(year, month);
        Map<Integer, List<Map<String, Object>>> allCapacities = DatabaseService.getAllCapacities();
        Map<Integer, List<Map<String, Object>>> allTasks = DatabaseService.getActiveTaskAssignmentsForDateRange(monthStart, monthEnd);

        // Schritt 3: Füge die Daten für die sichtbaren Benutzer zusammen
        Map<String, List<Map<String, Object>>> departments = new LinkedHashMap<>();
        for (Map<String, Object> user : visibleUsers) {
            int userId = (Integer) user.get("id");

            user.put("absences", allAbsences.getOrDefault(userId, new ArrayList<>()));

            List<Map<String, Object>> userCapacities = allCapacities.getOrDefault(userId, new ArrayList<>());

            // FINALE KORREKTUR:
            // 1. Verwendet den korrekten Schlüssel 'start_date'.
            // 2. Ist sicher gegen null-Werte im Datum (Comparator.nullsLast).
            userCapacities.sort(
                Comparator.comparing(
                    (Map<String, Object> m) -> (LocalDate) m.get("start_date"),
                    Comparator.nullsLast(Comparator.reverseOrder())
                )
            );
            
            user.put("capacities", userCapacities);
            user.put("tasks", allTasks.getOrDefault(userId, new ArrayList<>()));

            String department = (String) user.get("abteilung");
            departments.computeIfAbsent(department != null ? department : "Ohne Abteilung", k -> new ArrayList<>()).add(user);
        }
        return departments;
    }     

    /**
     * Erstellt eine Liste aller Tage eines Monats mit Zusatzinformationen.
     */
    private List<Map<String, Object>> getDaysOfMonth(int year, int month) throws SQLException {
        List<Map<String, Object>> days = new ArrayList<>();
        LocalDate date = LocalDate.of(year, month, 1);
        int daysInMonth = date.lengthOfMonth();
        List<Map<String, Object>> holidays = DatabaseService.getHolidaysForMonth(year, month);

        for (int i = 1; i <= daysInMonth; i++) {
            LocalDate day = LocalDate.of(year, month, i);
            Map<String, Object> dayInfo = new HashMap<>();
            dayInfo.put("date", day.toString());
            dayInfo.put("dayOfMonth", i);
            dayInfo.put("isWeekend", day.getDayOfWeek().getValue() >= 6);

            // Prüfen, ob der Tag ein Feiertag ist
            boolean isHoliday = false;
            String holidayName = "";
            for (Map<String, Object> holiday : holidays) {
                if (day.equals(holiday.get("date"))) {
                    isHoliday = true;
                    holidayName = (String) holiday.get("name");
                    break;
                }
            }
            dayInfo.put("isHoliday", isHoliday);
            dayInfo.put("holidayName", holidayName);

            days.add(dayInfo);
        }
        return days;
    }
}