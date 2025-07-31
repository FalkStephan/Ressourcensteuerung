package com.example;

import org.apache.poi.ss.usermodel.*;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@WebServlet("/feiertage/import")
@MultipartConfig
public class ImportFeiertagServlet extends HttpServlet {
    @Override
    @SuppressWarnings("unchecked")
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        resp.setContentType("text/html;charset=UTF-8");
        HttpSession session = req.getSession(false);
        if (session == null || session.getAttribute("user") == null) {
            resp.sendError(HttpServletResponse.SC_FORBIDDEN);
            return;
        }
        
        Map<String, Object> user = (Map<String, Object>) session.getAttribute("user");
    // NEU: Rechteprüfung
    if (user == null || !Boolean.TRUE.equals(user.get("can_manage_feiertage"))) {
        resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Zugriff verweigert");
        return;
    }

        String actor = (String) user.get("username");
        
        StringBuilder html = new StringBuilder();
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
                    imported = importFromExcel(fileContent, errors, actor);
                } else if (fileName.endsWith(".csv") || fileName.endsWith(".txt")) {
                    imported = importFromCsv(fileContent, errors, actor);
                } else {
                    errors.add("Dateiformat nicht unterstützt. Bitte .csv, .txt oder .xlsx verwenden.");
                }
                
                html.append("<div class='import-feedback-success'><h3>Import abgeschlossen</h3>");
                html.append("<p>Erfolgreich importierte Feiertage: ").append(imported).append("</p>");
                if (!errors.isEmpty()) {
                    html.append("<p style='color:red;'>Fehler:</p><ul style='color:red; list-style-type:disc; padding-left:20px;'>");
                    for (String err : errors) {
                        html.append("<li>").append(err).append("</li>");
                    }
                    html.append("</ul>");
                }
                html.append("</div>");
            }
        } catch (Exception e) {
            html.append("<div class='import-feedback-error'>Fehler beim Import: ").append(e.getMessage()).append("</div>");
        }
        resp.getWriter().print(html.toString());
    }

    private int importFromExcel(InputStream input, List<String> errors, String actor) throws IOException {
        int count = 0;
        try (Workbook workbook = new XSSFWorkbook(input)) {
            Sheet sheet = workbook.getSheetAt(0);
            for (Row row : sheet) {
                if (row.getRowNum() == 0) continue; // Header überspringen
                
                try {
                    String dateStr = getCellString(row, 0);
                    String bezeichnung = getCellString(row, 1);
                    
                    if(dateStr.isEmpty() || bezeichnung.isEmpty()) continue; // Leere Zeile überspringen

                    LocalDate datum = parseDate(dateStr);
                    
                    if (DatabaseService.getFeiertagByDate(datum) == null) {
                        DatabaseService.addFeiertag(datum, bezeichnung, actor);
                        count++;
                    } else {
                        errors.add("Feiertag am " + dateStr + " existiert bereits und wurde übersprungen.");
                    }
                } catch (DateTimeParseException e) {
                    errors.add("Ungültiges Datumsformat in Zeile " + (row.getRowNum() + 1));
                } catch (SQLException e) {
                    errors.add("Datenbankfehler in Zeile " + (row.getRowNum() + 1) + ": " + e.getMessage());
                }
            }
        }
        return count;
    }

    private int importFromCsv(InputStream input, List<String> errors, String actor) throws IOException {
        int count = 0;
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(input, "UTF-8"))) {
            String line;
            int lineNum = 0;
            while ((line = reader.readLine()) != null) {
                lineNum++;
                if (lineNum == 1) continue; // Header überspringen
                
                String[] parts = line.split(";", -1);
                if (parts.length < 2 || parts[0].trim().isEmpty() || parts[1].trim().isEmpty()) continue;
                
                try {
                    String dateStr = parts[0].trim();
                    String bezeichnung = parts[1].trim();

                    LocalDate datum = parseDate(dateStr);
                    
                    if (DatabaseService.getFeiertagByDate(datum) == null) {
                        DatabaseService.addFeiertag(datum, bezeichnung, actor);
                        count++;
                    } else {
                        errors.add("Feiertag am " + dateStr + " existiert bereits und wurde übersprungen.");
                    }
                } catch (DateTimeParseException e) {
                    errors.add("Ungültiges Datumsformat in Zeile " + lineNum);
                } catch (SQLException e) {
                    errors.add("Datenbankfehler in Zeile " + lineNum + ": " + e.getMessage());
                }
            }
        }
        return count;
    }
    
    // Erkennt dd.MM.yyyy und yyyy-MM-dd
    private LocalDate parseDate(String dateStr) throws DateTimeParseException {
        try {
            return LocalDate.parse(dateStr, DateTimeFormatter.ofPattern("dd.MM.yyyy"));
        } catch (DateTimeParseException e) {
            return LocalDate.parse(dateStr, DateTimeFormatter.ISO_LOCAL_DATE);
        }
    }

    private String getCellString(Row row, int idx) {
        Cell cell = row.getCell(idx, Row.MissingCellPolicy.RETURN_BLANK_AS_NULL);
        if (cell == null) return "";
        if (cell.getCellType() == CellType.NUMERIC && DateUtil.isCellDateFormatted(cell)) {
            return cell.getLocalDateTimeCellValue().toLocalDate().format(DateTimeFormatter.ISO_LOCAL_DATE);
        }
        return new DataFormatter().formatCellValue(cell).trim();
    }
}