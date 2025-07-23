<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<!DOCTYPE html>
<html lang="de">
<head>
    <c:set var="title" value="Neuer Mitarbeiter" scope="request" />
    <jsp:include page="/WEB-INF/_header.jsp" />
</head>
<body>
    <div class="layout-wrapper">
        <jsp:include page="/WEB-INF/_nav.jsp" />
        <main>
            <div class="container">
                <h2>Neuen Mitarbeiter anlegen</h2>
                <form action="${pageContext.request.contextPath}/mitarbeiter/add" method="post">
                    <div class="form-group">
                        <label for="name">Name (Pflichtfeld):</label>
                        <input type="text" id="name" name="name" required>
                    </div>
                    <div class="form-group">
                        <label for="abteilung">Abteilung (Pflichtfeld):</label>
                        <input type="text" id="abteilung" name="abteilung" required>
                    </div>
                    <div class="form-group">
                        <label for="stelle">Stelle (optional):</label>
                        <input type="text" id="stelle" name="stelle">
                    </div>
                    <div class="form-group">
                        <label for="team">Team (optional):</label>
                        <input type="text" id="team" name="team">
                    </div>
                    <button type="submit" class="button create">Speichern</button>
                    <a href="${pageContext.request.contextPath}/mitarbeiter" class="button" style="background-color: #7f8c8d;">Abbrechen</a>
                </form>
            </div>
        </main>
    </div>
</body>
</html>