<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<!DOCTYPE html>
<html lang="de">
<head>
    <c:set var="title" value="Mitarbeiter" scope="request" />
    <jsp:include page="/WEB-INF/_header.jsp" />
</head>
<body>
    <div class="layout-wrapper">
        <jsp:include page="/WEB-INF/_nav.jsp" />
        <main>
            <div class="container">
                <h2>Mitarbeiter</h2>
                <button type="button" class="button create" onclick="showAddForm()">Neuen Mitarbeiter anlegen</button>
                <div class="search-container">
                    <input type="text" id="mitarbeiterSearch" onkeyup="filterMitarbeiterTable()" placeholder="Mitarbeiter suchen...">
                </div>
                <table id="mitarbeiterTable">
                    <thead>
                        <tr>
                            <th>Name</th>
                            <th>Stelle</th>
                            <th>Team</th>
                            <th>Abteilung</th>
                            <th>Aktionen</th>
                        </tr>
                    </thead>
                    <tbody>
                        <c:forEach var="m" items="${mitarbeiter}">
                            <tr>
                                <td><c:out value="${m.name}" /></td>
                                <td><c:out value="${m.stelle}" /></td>
                                <td><c:out value="${m.team}" /></td>
                                <td><c:out value="${m.abteilung}" /></td>
                                <td>
                                    <button type="button" class="button small" 
                                        onclick="showEditForm(this)"
                                        data-id="${m.id}"
                                        data-name="${fn:escapeXml(m.name)}"
                                        data-stelle="${fn:escapeXml(m.stelle)}"
                                        data-team="${fn:escapeXml(m.team)}"
                                        data-abteilung="${fn:escapeXml(m.abteilung)}"
                                    >Bearbeiten</button>
                                    <button type="button" class="button small delete" onclick="showDeleteMitarbeiterModal(this)"
                                        data-id="${m.id}"
                                        data-name="${fn:escapeXml(m.name)}">
                                        Löschen
                                    </button>
                                </td>
    <!-- Modal für Löschen Mitarbeiter -->
    <div id="deleteMitarbeiterModal" class="modal-overlay" style="display:none;">
        <div class="modal-content">
            <p><strong id="deleteMitarbeiterName"></strong></p>
            <p id="deleteMitarbeiterText">Soll dieser Mitarbeiter wirklich gelöscht werden?</p>
            <form id="deleteMitarbeiterForm" method="post" action="mitarbeiter">
                <input type="hidden" name="action" value="delete" />
                <input type="hidden" name="id" id="deleteMitarbeiterId" />
                <div class="modal-buttons">
                    <button type="submit" class="button delete">Ja, löschen</button>
                    <button type="button" class="button" onclick="hideDeleteMitarbeiterModal()">Abbrechen</button>
                </div>
            </form>
        </div>
    </div>
    <script>
        // --- Löschen-Modal Mitarbeiter ---
        function showDeleteMitarbeiterModal(btn) {
            const id = btn.getAttribute('data-id');
            const name = btn.getAttribute('data-name');
            document.getElementById('deleteMitarbeiterId').value = id;
            document.getElementById('deleteMitarbeiterName').textContent = name;
            document.getElementById('deleteMitarbeiterText').innerHTML = 'Soll dieser Mitarbeiter wirklich gelöscht werden?';
            document.getElementById('deleteMitarbeiterModal').style.display = 'flex';
        }
        function hideDeleteMitarbeiterModal() {
            document.getElementById('deleteMitarbeiterModal').style.display = 'none';
        }
    </script>
                            </tr>
                        </c:forEach>
                        <c:if test="${empty mitarbeiter}">
                            <tr>
                                <td colspan="5" style="text-align: center;">Keine Mitarbeiter gefunden.</td>
                            </tr>
                        </c:if>
                    </tbody>
                </table>
            </div>
        </main>
    </div>

    <!-- Modal für Neuanlage/Bearbeiten -->
    <div id="mitarbeiterModal" class="modal-overlay" style="display:none;">
        <div class="modal-content">
            <form id="mitarbeiterForm" method="post" action="mitarbeiter">
                <input type="hidden" name="action" id="formAction" value="add" />
                <input type="hidden" name="id" id="formId" />
                <div>
                    <label for="formName">Name<span class="required-star">*</span>:</label>
                    <input type="text" name="name" id="formName" required />
                </div>
                <div>
                    <label for="formStelle">Stelle:</label>
                    <input type="text" name="stelle" id="formStelle" />
                </div>
                <div>
                    <label for="formTeam">Team:</label>
                    <input type="text" name="team" id="formTeam" />
                </div>
                <div>
                    <label for="formAbteilung">Abteilung<span class="required-star">*</span>:</label>
                    <input type="text" name="abteilung" id="formAbteilung" required />
                </div>
                <div class="modal-buttons">
                    <button type="submit" class="button create">Speichern</button>
                    <button type="button" class="button delete" onclick="hideModal()">Abbrechen</button>
                </div>
            </form>
        </div>
    </div>

    <script>
        // --- Live-Suche ---
        function filterMitarbeiterTable() {
            const input = document.getElementById('mitarbeiterSearch');
            const filter = input.value.toLowerCase();
            const table = document.getElementById('mitarbeiterTable');
            const tr = table.getElementsByTagName('tr');
            for (let i = 1; i < tr.length; i++) {
                let show = false;
                const tds = tr[i].getElementsByTagName('td');
                for (let j = 0; j < tds.length - 1; j++) {
                    if (tds[j].textContent.toLowerCase().indexOf(filter) > -1) {
                        show = true;
                    }
                }
                tr[i].style.display = show ? '' : 'none';
            }
        }

        // Modal-Logik für Neu/Bearbeiten
        function showAddForm() {
            document.getElementById('formAction').value = 'add';
            document.getElementById('formId').value = '';
            document.getElementById('formName').value = '';
            document.getElementById('formStelle').value = '';
            document.getElementById('formTeam').value = '';
            document.getElementById('formAbteilung').value = '';
            document.getElementById('mitarbeiterModal').style.display = 'flex';
        }
        function showEditForm(btn) {
            document.getElementById('formAction').value = 'edit';
            document.getElementById('formId').value = btn.dataset.id;
            document.getElementById('formName').value = btn.dataset.name;
            document.getElementById('formStelle').value = btn.dataset.stelle;
            document.getElementById('formTeam').value = btn.dataset.team;
            document.getElementById('formAbteilung').value = btn.dataset.abteilung;
            document.getElementById('mitarbeiterModal').style.display = 'flex';
        }
        function hideModal() {
            document.getElementById('mitarbeiterModal').style.display = 'none';
        }
    </script>
