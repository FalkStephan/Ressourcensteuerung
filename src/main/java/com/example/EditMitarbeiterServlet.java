package com.example;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.sql.SQLException;

@WebServlet("/mitarbeiter/edit")
public class EditMitarbeiterServlet extends HttpServlet {

    private final MitarbeiterDAO mitarbeiterDAO = new MitarbeiterDAO();
    private final LogDAO logDAO = new LogDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        try {
            int id = Integer.parseInt(request.getParameter("id"));
            Mitarbeiter mitarbeiter = mitarbeiterDAO.getMitarbeiterById(id); // Annahme: diese Methode existiert in MitarbeiterDAO
            if (mitarbeiter == null) {
                response.sendError(HttpServletResponse.SC_NOT_FOUND);
                return;
            }
            request.setAttribute("mitarbeiter", mitarbeiter);
            request.getRequestDispatcher("/WEB-INF/edit-mitarbeiter.jsp").forward(request, response);
        } catch (NumberFormatException | SQLException e) {
            throw new ServletException("Fehler beim Laden des Mitarbeiters", e);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");
        try {
            int id = Integer.parseInt(request.getParameter("id"));
            String name = request.getParameter("name");
            String abteilung = request.getParameter("abteilung");
            String stelle = request.getParameter("stelle");
            String team = request.getParameter("team");

            Mitarbeiter mitarbeiter = new Mitarbeiter(id, name, stelle, team, abteilung);
            mitarbeiterDAO.updateMitarbeiter(mitarbeiter);
            logDAO.addLogEintrag(new LogEintrag("UPDATE_MITARBEITER", "Mitarbeiter '" + name + "' (ID: " + id + ") wurde aktualisiert."));

        } catch (NumberFormatException | SQLException e) {
            throw new ServletException("Fehler beim Speichern des Mitarbeiters", e);
        }
        response.sendRedirect(request.getContextPath() + "/mitarbeiter");
    }
}