<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Benutzer bearbeiten</title>
    <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.3.1/css/bootstrap.min.css">
</head>
<body>

    <div class="container">
        <h2 class="mt-4">Benutzer bearbeiten</h2>

        <form action="editUser" method="post">
            <input type="hidden" name="id" value="<c:out value='${user.id}' />" />

            <div class="form-group">
                <label for="username">Benutzername:</label>
                <input type="text" class="form-control" id="username" name="username" value="<c:out value='${user.username}' />" required>
            </div>

            <div class="form-group">
                <label for="password">Neues Passwort (optional):</label>
                <input type="password" class="form-control" id="password" name="password">
                <small class="form-text text-muted">Lassen Sie dieses Feld leer, um das Passwort nicht zu ändern.</small>
            </div>
            
            <hr>
            
            <div class="form-group">
                <label for="abteilung">Abteilung (optional):</label>
                <input type="text" class="form-control" id="abteilung" name="abteilung" value="<c:out value='${user.abteilung}' />">
            </div>

            <div class="form-check mb-3">
                <input type="checkbox" class="form-check-input" id="hatBenutzerverwaltung" name="hatBenutzerverwaltung" value="true" <c:if test="${user.hatBenutzerverwaltung}">checked</c:if>>
                <label class="form-check-label" for="hatBenutzerverwaltung">
                    Hat Recht zur Benutzerverwaltung
                </label>
            </div>
            
            <hr>

            <button type="submit" class="btn btn-primary">Speichern</button>
            <a href="users" class="btn btn-secondary">Abbrechen</a>
        </form>
    </div>

</body>
</html>