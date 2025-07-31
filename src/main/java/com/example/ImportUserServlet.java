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

@WebServlet("/users/import")
@MultipartConfig
public class ImportUserServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        resp.setContentType("text/html;charset=UTF-8");
        java.io.PrintWriter out = resp.getWriter();
        StringBuilder html = new StringBuilder();

        // Parameter aus der Anfrage lesen
        boolean updateExisting = req.getParameter("update_existing") != null;
        boolean importNew = req.getParameter("import_new") != null;
        boolean deactivateMissing = req.getParameter("deactivate_missing") != null;
        
        List<String> importedUsernames = new ArrayList<>();

        try {
            jakarta.servlet.http.Part filePart = req.getPart("importFile");
            if (filePart == null) {
                html.append("<div class='import-feedback-error'>Keine Datei hochgeladen.</div>");
            } else {
                String fileName = filePart.getSubmittedFileName();
                InputStream fileContent = filePart.getInputStream();
                List<String> errors = new ArrayList<>();
                int importedCount = 0;

                if (fileName.toLowerCase().endsWith(".xlsx") || fileName.toLowerCase().endsWith(".xls")) {
                    importedCount = importFromExcel(fileContent, errors, updateExisting, importNew, importedUsernames);
                } else if (fileName.toLowerCase().endsWith(".csv") || fileName.toLowerCase().endsWith(".txt")) {
                    importedCount = importFromCsv(fileContent, errors, updateExisting, importNew, importedUsernames);
                } else {
                    errors.add("Dateiformat nicht unterstützt.");
                }

                if (deactivateMissing && !importedUsernames.isEmpty()) {
                    int deactivatedCount = DatabaseService.deactivateUsersNotIn(importedUsernames);
                    html.append("<div class='import-feedback-info'>").append(deactivatedCount).append(" Benutzer wurden deaktiviert.</div>");
                }

                html.append("<div class='import-feedback-success'><h3>Import abgeschlossen</h3>");
                html.append("<p>Importierte/Aktualisierte Benutzer: ").append(importedCount).append("</p>");
                if (!errors.isEmpty()) {
                    html.append("<ul style='color:red;'>");
                    for (String err : errors) {
                        html.append("<li>").append(err).append("</li>");
                    }
                    html.append("</ul>");
                }
                html.append("</div>");
            }
        } catch (Exception e) {
            html.append("<div class='import-feedback-error'>Fehler beim Import: ").append(e.getMessage()).append("</div>");
            e.printStackTrace();
        }
        out.print(html.toString());
    }

    private int importFromExcel(InputStream input, List<String> errors, boolean updateExisting, boolean importNew, List<String> importedUsernames) throws IOException {
        int count = 0;
        try (Workbook workbook = new XSSFWorkbook(input)) {
            Sheet sheet = workbook.getSheetAt(0);
            for (Row row : sheet) {
                if (row.getRowNum() == 0) continue;

                try {
                    String username = getCellString(row, 0);
                    if (username.isEmpty()) continue;

                    String name = getCellString(row, 1);
                    String vorname = getCellString(row, 2);
                    String abteilung = getCellString(row, 3);
                    String team = getCellString(row, 4);
                    String stelle = getCellString(row, 5);
                    boolean active = "1".equals(getCellString(row, 6));
                    boolean isUser = "1".equals(getCellString(row, 7));
                    boolean canManageUsers = "1".equals(getCellString(row, 8));
                    boolean canViewLogbook = "1".equals(getCellString(row, 9));
                    boolean canManageFeiertage = "1".equals(getCellString(row, 10)); // NEU
                    String password = username;
                    
                    importedUsernames.add(username);

                    Map<String, Object> existing = DatabaseService.getUserByUsername(username);
                    if (existing != null) {
                        if (updateExisting) {
                            int id = (int) existing.get("id");
                            DatabaseService.updateUser(id, username, password, name, vorname, stelle, team, canManageUsers, canViewLogbook, canManageFeiertage, abteilung, "import", active, isUser);
                            count++;
                        }
                    } else {
                        if (importNew) {
                            DatabaseService.addUser(username, password, name, vorname, stelle, team, canManageUsers, canViewLogbook, canManageFeiertage, abteilung, "import", active, isUser);
                            count++;
                        }
                    }
                } catch (Exception e) {
                    errors.add("Fehler in Zeile " + (row.getRowNum() + 1) + ": " + e.getMessage());
                }
            }
        }
        return count;
    }

    private int importFromCsv(InputStream input, List<String> errors, boolean updateExisting, boolean importNew, List<String> importedUsernames) throws IOException {
        int count = 0;
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(input, "UTF-8"))) {
            String line;
            int lineNum = 0;
            while ((line = reader.readLine()) != null) {
                lineNum++;
                if (lineNum == 1) continue;

                String[] parts = line.split(";", -1);
                if (parts.length < 11) continue;

                try {
                    String username = parts[0].trim();
                    if (username.isEmpty()) continue;

                    String name = parts[1].trim();
                    String vorname = parts[2].trim();
                    String abteilung = parts[3].trim();
                    String team = parts[4].trim();
                    String stelle = parts[5].trim();
                    boolean active = "1".equals(parts[6].trim());
                    boolean isUser = "1".equals(parts[7].trim());
                    boolean canManageUsers = "1".equals(parts[8].trim());
                    boolean canViewLogbook = "1".equals(parts[9].trim());
                    boolean canManageFeiertage = "1".equals(parts[10].trim()); // NEU
                    String password = username;
                    
                    importedUsernames.add(username);

                    Map<String, Object> existing = DatabaseService.getUserByUsername(username);
                     if (existing != null) {
                        if (updateExisting) {
                            int id = (int) existing.get("id");
                            DatabaseService.updateUser(id, username, password, name, vorname, stelle, team, canManageUsers, canViewLogbook, canManageFeiertage, abteilung, "import", active, isUser);
                            count++;
                        }
                    } else {
                        if (importNew) {
                            DatabaseService.addUser(username, password, name, vorname, stelle, team, canManageUsers, canViewLogbook, canManageFeiertage, abteilung, "import", active, isUser);
                            count++;
                        }
                    }
                } catch (Exception e) {
                    errors.add("Fehler in Zeile " + lineNum + ": " + e.getMessage());
                }
            }
        }
        return count;
    }

    private String getCellString(Row row, int idx) {
        Cell cell = row.getCell(idx, Row.MissingCellPolicy.RETURN_BLANK_AS_NULL);
        if (cell == null) return "";
        return new DataFormatter().formatCellValue(cell).trim();
    }
}