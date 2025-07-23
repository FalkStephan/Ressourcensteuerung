<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<!DOCTYPE html>
<html lang="de">
<head>
    <c:set var="title" value="Mitarbeiterverwaltung" scope="request" />
    <jsp:include page="/WEB-INF/_header.jsp" />
</head>
<body>
    <div class="layout-wrapper">
        <jsp:include page="/WEB-INF/_nav.jsp" />
        <main>
            <div class="container">
                <h2>Mitarbeiterverwaltung</h2>
                <a href="${pageContext.request.contextPath}/mitarbeiter/add" class="button create">Neuen Mitarbeiter anlegen</a>

                <div class="search-container">
                    <input type="text" id="mitarbeiterSearch" onkeyup="filterTable()" placeholder="Mitarbeiter suchen...">
                </div>

                <table id="mitarbeiterTable">
                    <thead>
                        <tr>
                            <th class="sortable-header" onclick="sortTable(0, 'string')">Name</th>
                            <th class="sortable-header" onclick="sortTable(1, 'string')">Stelle</th>
                            <th class="sortable-header" onclick="sortTable(2, 'string')">Team</th>
                            <th class="sortable-header" onclick="sortTable(3, 'string')">Abteilung</th>
                            <th>Aktionen</th>
                        </tr>
                    </thead>
                    <tbody>
                        <c:forEach var="m" items="${mitarbeiterListe}">
                            <tr>
                                <td><c:out value="${m.name}" /></td>
                                <td><c:out value="${m.stelle}" /></td>
                                <td><c:out value="${m.team}" /></td>
                                <td><c:out value="${m.abteilung}" /></td>
                                <td>
                                    <a href="${pageContext.request.contextPath}/mitarbeiter/edit?id=${m.id}" class="button small">Bearbeiten</a>
                                    <form action="${pageContext.request.contextPath}/mitarbeiter/delete" method="post" style="display:inline;" class="delete-form">
                                        <input type="hidden" name="id" value="${m.id}">
                                        <button type="submit" class="button small delete" onclick="event.preventDefault(); showConfirmModal(this.form);">Löschen</button>
                                    </form>
                                </td>
                            </tr>
                        </c:forEach>
                        <c:if test="${empty mitarbeiterListe}">
                            <tr>
                                <td colspan="5" style="text-align: center;">Keine Mitarbeiter gefunden.</td>
                            </tr>
                        </c:if>
                    </tbody>
                </table>
            </div>
        </main>
    </div>

    <div id="confirmModal" class="modal-overlay">
        <div class="modal-content">
            <p>Soll dieser Mitarbeiter wirklich gelöscht werden?</p>
            <div class="modal-buttons">
                <button id="cancelDeleteBtn" class="button" style="background-color: #7f8c8d;">Abbrechen</button>
                <button id="confirmDeleteBtn" class="button delete">Ja, löschen</button>
            </div>
        </div>
    </div>

    <script>
        // --- Live-Suche (angepasst für Mitarbeiter) ---
        function filterTable() {
            const input = document.getElementById('mitarbeiterSearch');
            const filter = input.value.toLowerCase();
            const table = document.getElementById('mitarbeiterTable');
            const tr = table.getElementsByTagName('tr');

            for (let i = 1; i < tr.length; i++) {
                const tdName = tr[i].getElementsByTagName('td')[0]; // Spalte 0 = Name
                if (tdName) {
                    const txtValue = tdName.textContent || tdName.innerText;
                    if (txtValue.toLowerCase().indexOf(filter) > -1) {
                        tr[i].style.display = "";
                    } else {
                        tr[i].style.display = "none";
                    }
                }
            }
        }

        // --- Bestätigungs-Modal (Code kann wiederverwendet werden) ---
        const modal = document.getElementById('confirmModal');
        const confirmBtn = document.getElementById('confirmDeleteBtn');
        const cancelBtn = document.getElementById('cancelDeleteBtn');
        let formToSubmit = null;

        function showConfirmModal(form) {
            formToSubmit = form;
            modal.style.display = 'flex';
        }

        function hideModal() {
            modal.style.display = 'none';
            formToSubmit = null;
        }

        confirmBtn.addEventListener('click', () => {
            if (formToSubmit) {
                formToSubmit.submit();
            }
        });

        cancelBtn.addEventListener('click', hideModal);
        modal.addEventListener('click', (event) => {
            if (event.target === modal) {
                hideModal();
            }
        });

        // --- Tabellen-Sortierung (Code kann wiederverwendet werden) ---
        let currentSortColumn = -1;
        let currentSortDir = 'asc';

        function sortTable(columnIndex, type) {
            const table = document.getElementById('mitarbeiterTable');
            const tbody = table.querySelector('tbody');
            const rows = Array.from(tbody.querySelectorAll('tr'));
            const headers = table.querySelectorAll('.sortable-header');
            const sortDir = (columnIndex === currentSortColumn && currentSortDir === 'asc') ? 'desc' : 'asc';
            
            rows.sort((a, b) => {
                const cellA = a.querySelectorAll('td')[columnIndex].innerText.toLowerCase();
                const cellB = b.querySelectorAll('td')[columnIndex].innerText.toLowerCase();
                let valA = cellA;
                let valB = cellB;
                if (type === 'number') {
                    valA = parseInt(valA, 10) || 0;
                    valB = parseInt(valB, 10) || 0;
                }
                if (valA < valB) return sortDir === 'asc' ? -1 : 1;
                if (valA > valB) return sortDir === 'asc' ? 1 : -1;
                return 0;
            });

            headers.forEach(header => header.classList.remove('asc', 'desc'));
            headers[columnIndex].classList.add(sortDir);
            tbody.innerHTML = '';
            rows.forEach(row => tbody.appendChild(row));
            
            currentSortColumn = columnIndex;
            currentSortDir = sortDir;
        }
    </script>
</body>
</html>