package com.example;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.google.gson.JsonSyntaxException;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

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

        try (PrintWriter out = resp.getWriter()) {
            int year = Integer.parseInt(req.getParameter("year"));
            int month = Integer.parseInt(req.getParameter("month"));

            Map<String, Object> responseData = new HashMap<>();
            
            // --- Schritt 1: Tage und Feiertage abrufen ---
            try {
                responseData.put("days", getDaysOfMonth(year, month));
            } catch (Exception e) {
                resp.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
                out.print("{\"error\": \"Fehler beim Abrufen der Tage und Feiertage: " + e.getMessage().replace("\"", "'") + "\"}");
                e.printStackTrace();
                return; // Wichtig: Ausführung hier beenden
            }

            // --- Schritt 2: Benutzer, Abwesenheiten und Kapazitäten abrufen ---
            try {
                responseData.put("departments", getAllUsersWithAbsencesAndDepartments(year, month));
            } catch (Exception e) {
                resp.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
                out.print("{\"error\": \"Fehler beim Abrufen der Benutzerdaten: " + e.getMessage().replace("\"", "'") + "\"}");
                e.printStackTrace();
                return;
            }

            // --- Schritt 3: Kalenderfarben abrufen ---
            try {
                responseData.put("colors", DatabaseService.getCalendarColors());
            } catch (Exception e) {
                resp.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
                out.print("{\"error\": \"Fehler beim Abrufen der Kalenderfarben: " + e.getMessage().replace("\"", "'") + "\"}");
                e.printStackTrace();
                return;
            }

            // Wenn alles erfolgreich war, die vollständige Antwort senden
            String jsonResponse = gson.toJson(responseData);
            out.print(jsonResponse);

        } catch (NumberFormatException e) {
            resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            resp.getWriter().write("{\"error\": \"Ungültige Jahres- oder Monatsangabe.\"}");
        } catch (Exception e) {
            // Dieser Block fängt allgemeine Fehler ab, z.B. wenn getWriter() fehlschlägt
            resp.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            resp.getWriter().write("{\"error\": \"Allgemeiner Serverfehler: " + e.getMessage().replace("\"", "'") + "\"}");
            e.printStackTrace();
        }
    }

    /**
     * Stellt die Daten für die Kalenderübersicht zusammen.
     * Holt Benutzer, Abwesenheiten und Kapazitäten und führt sie zusammen.
     */
    private Map<String, List<Map<String, Object>>> getAllUsersWithAbsencesAndDepartments(int year, int month) throws SQLException {
        LocalDate monthStart = LocalDate.of(year, month, 1);
        LocalDate monthEnd = monthStart.with(TemporalAdjusters.lastDayOfMonth());
        List<Map<String, Object>> users = DatabaseService.getAllActiveUsers();
        Map<Integer, List<String>> allAbsences = DatabaseService.getAbsencesForMonth(year, month);
        Map<Integer, List<Map<String, Object>>> allCapacities = DatabaseService.getAllCapacities();
        Map<Integer, List<Map<String, Object>>> allTasks = DatabaseService.getActiveTaskAssignmentsForDateRange(monthStart, monthEnd);

        Map<String, List<Map<String, Object>>> departments = new LinkedHashMap<>();
        for (Map<String, Object> user : users) {
            int userId = (Integer) user.get("id");
            user.put("absences", allAbsences.getOrDefault(userId, new ArrayList<>()));

            List<Map<String, Object>> userCapacities = allCapacities.getOrDefault(userId, new ArrayList<>());

            // Kapazitäten absteigend sortieren
            Collections.sort(userCapacities, new Comparator<Map<String, Object>>() {
                @Override
                public int compare(Map<String, Object> o1, Map<String, Object> o2) {
                    Object dateObj1 = o1.get("start_date");
                    Object dateObj2 = o2.get("start_date");

                    if (dateObj1 instanceof LocalDate && dateObj2 instanceof LocalDate) {
                        return ((LocalDate) dateObj2).compareTo((LocalDate) dateObj1);
                    }
                    return 0;
                }
            });

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