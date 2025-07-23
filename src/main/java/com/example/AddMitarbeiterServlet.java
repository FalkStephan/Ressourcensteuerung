package com.example;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.sql.SQLException;

@WebServlet("/mitarbeiter/add")
public class AddMitarbeiterServlet extends HttpServlet {

    private final MitarbeiterDAO mitarbeiterDAO = new MitarbeiterDAO();
    private final LogDAO logDAO = new LogDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        request.getRequestDispatcher("/WEB-INF/add-mitarbeiter.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");
        String name = request.getParameter("name");
        String abteilung = request.getParameter("abteilung");
        String stelle = request.getParameter("stelle");
        String team = request.getParameter("team");

        if (name == null || name.trim().isEmpty() || abteilung == null || abteilung.trim().isEmpty()) {
            // Fehlerbehandlung für Pflichtfelder
            request.setAttribute("error", "Name und Abteilung sind Pflichtfelder.");
            request.getRequestDispatcher("/WEB-INF/add-mitarbeiter.jsp").forward(request, response);
            return;
        }

        Mitarbeiter mitarbeiter = new Mitarbeiter(name, stelle, team, abteilung);

        try {
            mitarbeiterDAO.addMitarbeiter(mitarbeiter);
            logDAO.addLogEintrag(new LogEintrag("CREATE_MITARBEITER", "Mitarbeiter '" + name + "' wurde angelegt."));
        } catch (SQLException e) {
            throw new ServletException("Datenbankfehler beim Anlegen des Mitarbeiters", e);
        }

        response.sendRedirect(request.getContextPath() + "/mitarbeiter");
    }
}