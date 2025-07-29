
package com.example;

import org.apache.poi.ss.usermodel.*;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import java.io.InputStream;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.sql.SQLException;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;


@WebServlet(urlPatterns = {"/users/import", "/users/import/"})
@MultipartConfig
public class ImportUserServlet extends HttpServlet {
    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        resp.setContentType("text/html;charset=UTF-8");
        java.io.PrintWriter out = resp.getWriter();
        StringBuilder html = new StringBuilder();
        boolean updateExisting = req.getParameter("update_existing") != null;
        boolean importNew = req.getParameter("import_new") != null;
        try {
            jakarta.servlet.http.Part filePart = req.getPart("importFile");
            if (filePart == null) {
                html.append("<div class='import-feedback-error'>Keine Datei hochgeladen.</div>");
            } else {
                String fileName = filePart.getSubmittedFileName();
                InputStream fileContent = filePart.getInputStream();
                List<String> errors = new ArrayList<>();
                int imported = 0;
                if (fileName.endsWith(".xlsx") || fileName.endsWith(".xls")) {
                    imported = importFromExcel(fileContent, errors, updateExisting, importNew);
                } else if (fileName.endsWith(".csv") || fileName.endsWith(".txt")) {
                    imported = importFromCsv(fileContent, errors, updateExisting, importNew);
                } else {
                    errors.add("Dateiformat nicht unterstützt.");
                }
                html.append("<div class='import-feedback-success'><h3>Import abgeschlossen</h3>");
                html.append("<p>Importierte Benutzer: " + imported + "</p>");
                if (!errors.isEmpty()) {
                    html.append("<ul style='color:red;'>");
                    for (String err : errors) html.append("<li>" + err + "</li>");
                    html.append("</ul>");
                }
                html.append("</div>");
            }
        } catch (Exception e) {
            html.append("<div class='import-feedback-error'>Fehler beim Import: " + e.getMessage() + "</div>");
        }
        out.print(html.toString());
    }

    private int importFromExcel(InputStream input, List<String> errors, boolean updateExisting, boolean importNew) throws IOException, SQLException {
        int count = 0;
        Workbook workbook = new XSSFWorkbook(input);
        Sheet sheet = workbook.getSheetAt(0);
        for (Row row : sheet) {
            if (row.getRowNum() == 0) continue; // Header überspringen
            String username = getCellString(row, 0); // Mitarbeiterkennung *
            String name = getCellString(row, 1);     // Name *
            String vorname = getCellString(row, 2);  // Vorname *
            String abteilung = getCellString(row, 3);// Abteilung
            String team = getCellString(row, 4);     // Team
            String stelle = getCellString(row, 5);   // Stelle
            boolean active = "1".equals(getCellString(row, 6)); // aktiv
            boolean isUser = "1".equals(getCellString(row, 7)); // ist Benutzer
            boolean canManageUsers = "1".equals(getCellString(row, 8)); // Benutzerverwaltung
            boolean canViewLogbook = "1".equals(getCellString(row, 9)); // Logbuch
            String password = username; // Passwort = Mitarbeiterkennung
            try {
                Map<String, Object> existing = DatabaseService.getUserByUsername(username);
                if (updateExisting && existing != null) {
                    int id = (int) existing.get("id");
                    DatabaseService.updateUser(id, username, password, name, vorname, stelle, team, canManageUsers, canViewLogbook, abteilung, "import", active, isUser);
                } else if (existing == null && importNew) {
                    DatabaseService.addUser(username, password, name, vorname, stelle, team, canManageUsers, canViewLogbook, abteilung, "import", active, isUser);
                } else if (existing != null && !updateExisting) {
                    errors.add("Benutzer '" + username + "' existiert bereits und 'aktualisieren' ist nicht gesetzt.");
                    continue;
                }
                count++;
            } catch (Exception e) {
                errors.add("Fehler bei Benutzer '" + username + "': " + e.getMessage());
            }
        }
        workbook.close();
        return count;
    }

    private int importFromCsv(InputStream input, List<String> errors, boolean updateExisting, boolean importNew) throws IOException, SQLException {
        int count = 0;
        BufferedReader reader = new BufferedReader(new InputStreamReader(input, "UTF-8"));
        String line;
        boolean first = true;
        while ((line = reader.readLine()) != null) {
            if (first) { first = false; continue; }
            String[] parts = line.split(";");
            if (parts.length < 3) continue;
            String username = parts.length > 0 ? parts[0] : "";      // Mitarbeiterkennung *
            String name = parts.length > 1 ? parts[1] : "";           // Name *
            String vorname = parts.length > 2 ? parts[2] : "";        // Vorname *
            String abteilung = parts.length > 3 ? parts[3] : "";      // Abteilung
            String team = parts.length > 4 ? parts[4] : "";           // Team
            String stelle = parts.length > 5 ? parts[5] : "";         // Stelle
            boolean active = parts.length > 6 && "1".equals(parts[6]); // aktiv
            boolean isUser = parts.length > 7 && "1".equals(parts[7]); // ist Benutzer
            boolean canManageUsers = parts.length > 8 && "1".equals(parts[8]); // Benutzerverwaltung
            boolean canViewLogbook = parts.length > 9 && "1".equals(parts[9]); // Logbuch
            String password = username; // Passwort = Mitarbeiterkennung
            try {
                Map<String, Object> existing = DatabaseService.getUserByUsername(username);
                if (updateExisting && existing != null) {
                    int id = (int) existing.get("id");
                    DatabaseService.updateUser(id, username, password, name, vorname, stelle, team, canManageUsers, canViewLogbook, abteilung, "import", active, isUser);
                } else if (existing == null && importNew) {
                    DatabaseService.addUser(username, password, name, vorname, stelle, team, canManageUsers, canViewLogbook, abteilung, "import", active, isUser);
                } else if (existing != null && !updateExisting) {
                    errors.add("Benutzer '" + username + "' existiert bereits und 'aktualisieren' ist nicht gesetzt.");
                    continue;
                }
                count++;
            } catch (Exception e) {
                errors.add("Fehler bei Benutzer '" + username + "': " + e.getMessage());
            }
        }
        return count;
    }

    private String getCellString(Row row, int idx) {
        Cell cell = row.getCell(idx);
        if (cell == null) return "";
        if (cell.getCellType() == CellType.NUMERIC) {
            return String.valueOf((int)cell.getNumericCellValue());
        }
        return cell.toString();
    }
}
