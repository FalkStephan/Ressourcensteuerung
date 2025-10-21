<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<!DOCTYPE html>
<html lang="de">
<head>
    <c:set var="title" value="Feiertage" scope="request" />
    <jsp:include page="/WEB-INF/_header.jsp" />
</head>
<body>
    <div class="layout-wrapper">
        <jsp:include page="/WEB-INF/_nav.jsp" />
        <main>
            <div class="container">
                <h2>Feiertage verwalten</h2>
                <button type="button" class="button create" onclick="showAddForm()">Neuen Feiertag anlegen</button>
                <button type="button" class="button create" style="margin-left:1em;" onclick="showImportModal()">Feiertage importieren</button>

                <table id="feiertageTable">
                    <thead>
                        <tr>
                            <th>Datum</th>
                            <th>Bezeichnung</th>
                            <th>Aktionen</th>
                        </tr>
                    </thead>
                    <tbody>
                        <c:forEach var="ft" items="${feiertage}">
                            <tr>
                                <td><c:out value="${ft.date}" /></td>
                                <td><c:out value="${ft.name}" /></td>
                                <td>
                                    <button type="button" class="button small"
                                            onclick="showEditForm(this)"
                                            data-id="${ft.id}"
                                            data-datum="${ft.date}"
                                            data-bezeichnung="${fn:escapeXml(ft.name)}">
                                        Bearbeiten
                                    </button>
                                    <button type="button" class="button small delete" onclick="showDeleteModal(this)"
                                            data-id="${ft.id}"
                                            data-bezeichnung="${fn:escapeXml(ft.name)}"
                                            data-datum="${ft.date}">
                                        Löschen
                                    </button>
                                </td>
                            </tr>
                        </c:forEach>
                        <c:if test="${empty feiertage}">
                            <tr>
                                <td colspan="3" style="text-align: center;">Keine Feiertage gefunden.</td>
                            </tr>
                        </c:if>
                    </tbody>
                </table>
            </div>
        </main>
    </div>

    <div id="feiertagModal" class="modal-overlay" style="display:none;">
        <div class="modal-content">
            <form id="feiertagForm" method="post" action="feiertage">
                <input type="hidden" name="action" id="formAction" value="add" />
                <input type="hidden" name="id" id="formId" />
                <div>
                    <label for="formDatum">Datum<span class="required-star">*</span>:</label>
                    <input type="date" name="datum" id="formDatum" required />
                </div>
                <div>
                    <label for="formBezeichnung">Bezeichnung<span class="required-star">*</span>:</label>
                    <input type="text" name="bezeichnung" id="formBezeichnung" required />
                </div>
                <div class="modal-buttons">
                    <button type="submit" class="button create">Speichern</button>
                    <button type="button" class="button delete" onclick="hideModal()">Abbrechen</button>
                </div>
            </form>
        </div>
    </div>

    <div id="deleteModal" class="modal-overlay" style="display:none;">
        <div class="modal-content">
            <p>Soll der Feiertag <strong id="deleteName"></strong> am <strong id="deleteDate"></strong> wirklich gelöscht werden?</p>
            <form id="deleteForm" method="post" action="feiertage">

                <input type="hidden" name="action" value="delete" />
                <input type="hidden" name="id" id="deleteId" />
                <input type="hidden" name="bezeichnung" id="deleteName" />
                <input type="hidden" name="datum" id="deleteDate" />

                <div class="modal-buttons">
                    <button type="submit" class="button delete">Ja, löschen</button>
                    <button type="button" class="button" onclick="hideDeleteModal()">Abbrechen</button>
                </div>
            </form>
        </div>
    </div>
    
    <div id="importModal" class="modal-overlay" style="display:none;">
        <div class="modal-content" style="max-width:400px;">
            <h3>Feiertage importieren</h3>
            <p style="font-size: 0.9em; color: #555;">Die Datei muss die Spalten "Datum" und "Bezeichnung" enthalten. Die erste Zeile wird als Überschrift ignoriert.</p>
            <form id="importForm" method="post" action="${pageContext.request.contextPath}/feiertage/import" enctype="multipart/form-data">
                <input type="file" name="importFile" id="importFile" accept=".csv,.xlsx,.xls,.txt" required style="margin-bottom:1em;" />
                <div class="modal-buttons" style="display:flex; gap:0.5em;">
                    <button type="submit" class="button create">Datei importieren</button>
                    <button type="button" class="button delete" onclick="hideImportModal()">Abbrechen</button>
                </div>
            </form>
        </div>
    </div>

    <div id="importFeedbackModal" class="modal-overlay" style="display:none;">
        <div class="modal-content" style="max-width:400px;">
            <h3>Import-Ergebnis</h3>
            <div id="importFeedbackModalBody"></div>
            <div class="modal-buttons" style="margin-top:1em;">
                <button type="button" class="button" onclick="window.location.reload()">Schließen</button>
            </div>
        </div>
    </div>

    <script>
        function showAddForm() {
            document.getElementById('feiertagForm').reset();
            document.getElementById('formAction').value = 'add';
            document.getElementById('feiertagModal').style.display = 'flex';
        }

        function showEditForm(btn) {
            document.getElementById('feiertagForm').reset();
            document.getElementById('formAction').value = 'edit';
            document.getElementById('formId').value = btn.dataset.id;
            
            // Das 'YYYY-MM-DD'-Format von LocalDate.toString()
            // wird direkt in das Datumsfeld eingetragen.
            document.getElementById('formDatum').value = btn.dataset.datum;
            
            document.getElementById('formBezeichnung').value = btn.dataset.bezeichnung;
            document.getElementById('feiertagModal').style.display = 'flex';
        }

        function hideModal() {
            document.getElementById('feiertagModal').style.display = 'none';
        }

        function showDeleteModal(btn) {
            document.getElementById('deleteId').value = btn.dataset.id;
            document.getElementById('deleteName').textContent = btn.dataset.bezeichnung;

            console.log('Datum zum Löschen:', btn.dataset);
            
            // Datum auslesen (Format: YYYY-MM-DD)
            const isoDate = btn.dataset.datum;
            
            // In DD.MM.YYYY umwandeln
            try {
                const parts = isoDate.split('-');
                const formattedDate = parts[2] + '.' + parts[1] + '.' + parts[0];
                document.getElementById('deleteDate').textContent = formattedDate;
            } catch (e) {
                // Fallback, falls Datum ungültig ist
                document.getElementById('deleteDate').textContent = isoDate; 
            }
            
            document.getElementById('deleteModal').style.display = 'flex';
        }

        function hideDeleteModal() {
            document.getElementById('deleteModal').style.display = 'none';
        }
        
        function showImportModal() { document.getElementById('importModal').style.display = 'flex'; }
        function hideImportModal() { document.getElementById('importModal').style.display = 'none'; }
        
        document.addEventListener('DOMContentLoaded', function() {
            const importForm = document.getElementById('importForm');
            if(importForm) {
                importForm.addEventListener('submit', function(e) {
                    e.preventDefault();
                    const formData = new FormData(importForm);
                    fetch(importForm.action, { method: 'POST', body: formData })
                    .then(response => response.text())
                    .then(html => {
                        document.getElementById('importFeedbackModalBody').innerHTML = html;
                        hideImportModal();
                        document.getElementById('importFeedbackModal').style.display = 'flex';
                    })
                    .catch(err => {
                        document.getElementById('importFeedbackModalBody').innerHTML = '<div class="import-feedback-error">Fehler beim Upload.</div>';
                        hideImportModal();
                        document.getElementById('importFeedbackModal').style.display = 'flex';
                    });
                });
            }
        });
    </script>
</body>
</html>