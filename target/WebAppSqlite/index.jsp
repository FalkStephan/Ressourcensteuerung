<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<!DOCTYPE html>
<html lang="de">
<head>
    <c:set var="title" value="Willkommen" scope="request" />
    <jsp:include page="/WEB-INF/_header.jsp" />
</head>
<body>
    <div class="layout-wrapper">
        <jsp:include page="/WEB-INF/_nav.jsp" />
        <main>
            <div class="container">
                <h2>Willkommen bei Ihrer Anwendung!</h2>
                <p>Dies ist die Startseite. Bitte wählen Sie einen Punkt aus der Navigation auf der linken Seite, um zu beginnen.</p>
                <p>Sie können hier zum Beispiel:</p>
                <ul>
                    <li>Neue <strong>Kontakte</strong> anlegen und verwalten.</li>
                    <li>Die <strong>Benutzer</strong> der Anwendung administrieren.</li>
                    <li>Alle Änderungen im <strong>Logbuch</strong> nachverfolgen.</li>
                </ul>
            </div>
        </main>
    </div>
</body>
</html>