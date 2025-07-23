package com.example;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.sql.SQLException;

@WebServlet("/mitarbeiter/delete")
public class DeleteMitarbeiterServlet extends HttpServlet {

    private final MitarbeiterDAO mitarbeiterDAO = new MitarbeiterDAO();
    private final LogDAO logDAO = new LogDAO();

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        try {
            int id = Integer.parseInt(request.getParameter("id"));
            mitarbeiterDAO.deleteMitarbeiter(id);
            logDAO.addLogEintrag(new LogEintrag("DELETE_MITARBEITER", "Mitarbeiter mit ID " + id + " wurde gelöscht."));
        } catch (NumberFormatException | SQLException e) {
            throw new ServletException("Fehler beim Löschen des Mitarbeiters", e);
        }
        response.sendRedirect(request.getContextPath() + "/mitarbeiter");
    }
}