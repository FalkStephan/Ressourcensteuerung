package com.example;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.io.PrintWriter;
import java.sql.SQLException;
import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.YearMonth;
import java.time.format.DateTimeFormatter;
import java.util.*;
import com.google.gson.Gson;
import com.google.gson.GsonBuilder;

import java.util.stream.Collectors;
import java.util.stream.IntStream;
import java.util.logging.Logger;
import java.util.logging.Level;

@WebServlet(urlPatterns = {"/calendar-overview", "/calendar-overview/*"})
public class CalendarOverviewServlet extends HttpServlet {
    private static final Logger LOGGER = Logger.getLogger(CalendarOverviewServlet.class.getName());
    private final Gson gson = new GsonBuilder().create();

    // Map mit den Standardfarben, falls keine Einstellungen in der DB
    private final Map<String, String> DEFAULT_COLORS = Map.of(
        "calendar_color_holiday", "#ffe6e6",
        "calendar_color_weekend", "#f9f9f9",
        "calendar_color_absence", "#e6f3ff",
        "calendar_color_workday", "#e6ffe6"
    );

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        String pathInfo = request.getPathInfo();
        String servletPath = request.getServletPath();
        String requestURI = request.getRequestURI();
        
        // Prüfe, ob die Anfrage für Daten ist
        if (pathInfo != null && pathInfo.equals("/data") || requestURI.endsWith("/data")) {
            // API-Endpunkt für JSON-Daten
            handleDataRequest(request, response);
        } else {
            // Normale Seitenanfrage
            request.getRequestDispatcher("/WEB-INF/calendar_overview.jsp").forward(request, response);
        }
    }

    private void handleDataRequest(HttpServletRequest request, HttpServletResponse response) 
            throws IOException {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        
        try {
            // Überprüfe, ob die erforderlichen Parameter vorhanden sind
            String yearParam = request.getParameter("year");
            String monthParam = request.getParameter("month");
            
            if (yearParam == null || monthParam == null) {
                sendError(response, HttpServletResponse.SC_BAD_REQUEST, "Jahr und Monat müssen angegeben werden");
                return;
            }
            // Parameter auslesen
            int year = Integer.parseInt(request.getParameter("year"));
            int month = Integer.parseInt(request.getParameter("month"));
            
            // Monatsdaten erstellen
            YearMonth yearMonth = YearMonth.of(year, month);
            LocalDate firstDay = yearMonth.atDay(1);
            LocalDate lastDay = yearMonth.atEndOfMonth();
            
            // Hole den aktuell angemeldeten Benutzer aus der Session
            Map<String, Object> currentUser = (Map<String, Object>) request.getSession().getAttribute("user");
            if (currentUser == null) {
                sendError(response, HttpServletResponse.SC_UNAUTHORIZED, "Nicht angemeldet");
                return;
            }

            // Prüfe Benutzerrechte und hole entsprechende Mitarbeiter
            List<Map<String, Object>> employees;
            boolean seeAllUsers = (boolean) currentUser.get("see_all_users");
            
            if (seeAllUsers) {
                // Benutzer mit see_all_users Recht sehen alle aktiven Mitarbeiter
                employees = DatabaseService.getActiveUsersByDepartment(null);
            } else {
                // Andere Benutzer sehen nur Mitarbeiter ihrer eigenen Abteilung
                String userDepartment = (String) currentUser.get("abteilung");
                employees = DatabaseService.getActiveUsersByDepartment(userDepartment);
            }
            
            // Hole Feiertage für den Monat
            Map<LocalDate, String> holidays = DatabaseService.getHolidaysForMonth(year, month);
            
            // Hole Abwesenheiten für alle Mitarbeiter im Monat
            Map<Integer, List<LocalDate>> absences = new HashMap<>();
            for (Map<String, Object> employee : employees) {
                int userId = (int) employee.get("id");
                absences.put(userId, DatabaseService.getAbsencesForUser(userId, firstDay, lastDay));
            }
            
            // Lade Farbeinstellungen
            Map<String, String> colors = new HashMap<>(DEFAULT_COLORS);
            try {
                Map<String, String> dbColors = DatabaseService.getAllSettings();
                colors.putAll(dbColors);  // Überschreibe Standardwerte mit DB-Werten
            } catch (SQLException e) {
                // Bei Fehler werden die Standardfarben verwendet
                LOGGER.log(Level.SEVERE, "Fehler beim Laden der Farbeinstellungen", e);
            }
            
            // Erstelle die Antwort
            Map<String, Object> response_data = new HashMap<>();
            
            // Füge Farben zur Antwort hinzu
            response_data.put("colors", colors);
            
            // Tage des Monats mit Zusatzinformationen
            List<Map<String, Object>> days = new ArrayList<>();
            LocalDate currentDay = firstDay;
            while (!currentDay.isAfter(lastDay)) {
                Map<String, Object> dayInfo = new HashMap<>();
                dayInfo.put("date", currentDay.toString());
                dayInfo.put("dayOfMonth", currentDay.getDayOfMonth());
                dayInfo.put("isWeekend", isWeekend(currentDay));
                dayInfo.put("isHoliday", holidays.containsKey(currentDay));
                dayInfo.put("holidayName", holidays.get(currentDay));
                days.add(dayInfo);
                currentDay = currentDay.plusDays(1);
            }
            response_data.put("days", days);
            
            // Farben wurden bereits früher geladen und gesetzt
            
            // Mitarbeiter nach Abteilungen gruppieren
            Map<String, List<Map<String, Object>>> employeesByDepartment = new TreeMap<>();            for (Map<String, Object> employee : employees) {
                String department = (String) employee.get("abteilung");
                if (department == null || department.trim().isEmpty()) {
                    department = "Ohne Abteilung";
                }
                
                Map<String, Object> employeeInfo = new HashMap<>();
                employeeInfo.put("id", employee.get("id"));
                employeeInfo.put("name", employee.get("name") + ", " + employee.get("vorname"));
                
                List<String> absenceDates = new ArrayList<>();
                for (LocalDate date : absences.get(employee.get("id"))) {
                    absenceDates.add(date.toString());
                }
                employeeInfo.put("absences", absenceDates);
                
                employeesByDepartment.computeIfAbsent(department, k -> new ArrayList<>()).add(employeeInfo);
            }
            response_data.put("departments", employeesByDepartment);            // Sende JSON-Antwort
            response.setContentType("application/json");
            response.setCharacterEncoding("UTF-8");
            PrintWriter out = response.getWriter();
            out.print(gson.toJson(response_data));
            out.flush();
            
        } catch (SQLException e) {
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            response.getWriter().print("{\"error\": \"" + e.getMessage() + "\"}");
        }
    }
    
    private boolean isWeekend(LocalDate date) {
        DayOfWeek day = date.getDayOfWeek();
        return day == DayOfWeek.SATURDAY || day == DayOfWeek.SUNDAY;
    }
    
    private void sendError(HttpServletResponse response, int status, String message) throws IOException {
        response.setStatus(status);
        response.getWriter().print("{\"error\": \"" + message + "\"}");
    }
}
