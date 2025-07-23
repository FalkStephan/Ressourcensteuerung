<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>
<!DOCTYPE html>
<html lang="de">
<head>
    <c:set var="title" value="Logbuch" scope="request" />
    <jsp:include page="/WEB-INF/_header.jsp" />
    <style>
        .filter-bar {
            display: flex;
            gap: 15px;
            margin-bottom: 20px;
            align-items: center;
        }
        .pagination {
            display: flex;
            justify-content: center;
            align-items: center;
            gap: 15px;
            margin-top: 20px;
        }
    </style>
</head>
<body>
    <jsp:include page="/WEB-INF/_nav.jsp" />
    <main>
        <div class="container">
            <h2>Logbuch der Datenbankänderungen</h2>

            <form id="filterForm" action="${pageContext.request.contextPath}/logbook" method="get" class="filter-bar">
                <input type="text" id="searchInput" name="search" value="<c:out value="${search}"/>" placeholder="Suchen..." style="flex-grow: 1;">
                <select name="limit" onchange="this.form.submit()">
                    <option value="25" ${limit == 25 ? 'selected' : ''}>25 pro Seite</option>
                    <option value="50" ${limit == 50 ? 'selected' : ''}>50 pro Seite</option>
                    <option value="100" ${limit == 100 ? 'selected' : ''}>100 pro Seite</option>
                    <option value="250" ${limit == 250 ? 'selected' : ''}>250 pro Seite</option>
                </select>
            </form>

            <table>
                <thead>
                    <tr>
                        <th>Zeitstempel</th>
                        <th>Benutzer</th>
                        <th>Aktion</th>
                        <th>Beschreibung</th>
                    </tr>
                </thead>
                <tbody>
                    <c:forEach var="log" items="${logs}">
                        <tr>
                            <td><fmt:formatDate value="${log.timestamp}" pattern="dd.MM.yyyy HH:mm:ss" /></td>
                            <td><c:out value="${log.username}" /></td>
                            <td>
                                <c:choose>
                                    <c:when test="${log.action == 'Erstellen'}">
                                        <span class="log-action log-create">${log.action}</span>
                                    </c:when>
                                    <c:when test="${log.action == 'Bearbeiten'}">
                                        <span class="log-action log-edit">${log.action}</span>
                                    </c:when>
                                    <c:when test="${log.action == 'Löschen'}">
                                        <span class="log-action log-delete">${log.action}</span>
                                    </c:when>
                                    <c:otherwise>
                                        <span class="log-action log-auth">${log.action}</span>
                                    </c:otherwise>
                                </c:choose>
                            </td>
                            <td><c:out value="${log.description}" /></td>
                        </tr>
                    </c:forEach>
                    <c:if test="${empty logs}">
                        <tr>
                            <td colspan="4" style="text-align: center;">Keine Logbucheinträge für die aktuelle Auswahl gefunden.</td>
                        </tr>
                    </c:if>
                </tbody>
            </table>

            <div class="pagination">
                <c:if test="${currentPage > 1}">
                    <a href="?page=${currentPage - 1}&limit=${limit}&search=<c:out value="${search}"/>" class="button">&laquo; Zurück</a>
                </c:if>
                
                <c:if test="${totalPages > 0}">
                    <span>Seite ${currentPage} von ${totalPages}</span>
                </c:if>
                
                <c:if test="${currentPage < totalPages}">
                    <a href="?page=${currentPage + 1}&limit=${limit}&search=<c:out value="${search}"/>" class="button">Weiter &raquo;</a>
                </c:if>
            </div>
        </div>
    </main>
    
    <script>
        const searchInput = document.getElementById('searchInput');
        const filterForm = document.getElementById('filterForm');
        let debounceTimer;

        searchInput.addEventListener('keyup', () => {
            clearTimeout(debounceTimer);
            debounceTimer = setTimeout(() => {
                filterForm.submit();
            }, 500); // Wartet 500ms nach der letzten Eingabe, bevor die Suche startet
        });
    </script>
</body>
</html>
