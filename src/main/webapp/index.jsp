<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<!DOCTYPE html>
<html lang="de">
<head>
    <c:set var="title" value="Ressourcensteuerung" scope="request" />
    <jsp:include page="/WEB-INF/_header.jsp" />
</head>
<body>
    <div class="layout-wrapper">
        <jsp:include page="/WEB-INF/_nav.jsp" />
        <main>
            <div class="container">
                <h2>Willkommen bei Ihrer Ressourcensteuerung!</h2>
                <p>Dies ist die Startseite. Bitte wählen Sie einen Punkt aus der Navigation auf der linken Seite, um zu beginnen.</p>
                <p>Sie können hier zum Beispiel:</p>
                <ul>
                    <li><strong>Benutzer</strong> anlegen und verwalten.</li>
                    <li>Die <strong>Kapazitäten</strong> der Benutzer verwalten.</li>
                    <li>Die <strong>Abwesenheiten</strong> der Benutzer pflegen.</li>
                    <li><strong>Aufgaben</strong> anlegen und verwalten.</li>
                    <li>Den <strong>Kalander</strong> in der Monats-/Halbjahressicht ansehen.</li>
                    <li><strong>Feiertage</strong> verwalten.</li>
                    <li><strong>Einstellungen</strong> verwalten.</li>
                    <li>Alle Änderungen im <strong>Logbuch</strong> nachverfolgen.</li>
                </ul>
            </div>
        </main>
    </div>
</body>
</html>