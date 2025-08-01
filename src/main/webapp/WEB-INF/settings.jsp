<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<!DOCTYPE html>
<html lang="de">
<head>
    <c:set var="title" value="Einstellungen" scope="request"/>
    <jsp:include page="/WEB-INF/_header.jsp"/>
</head>
<body>
<div class="layout-wrapper">
    <jsp:include page="/WEB-INF/_nav.jsp"/>
    <main>
        <div class="container">
            <h2>Einstellungen</h2>
            <div class="user-card">
                <h3>Status "Aufgaben"</h3>
                <button class="button create small" onclick="showStatusModal('add')">Neuen Status anlegen</button>
                <table>
                    <thead><tr><th>Name</th><th>Aktiv</th><th>Reihenfolge</th><th>Aktionen</th></tr></thead>
                    <tbody>
                        <c:forEach var="status" items="${taskStatuses}">
                            <tr>
                                <td><c:out value="${status.name}"/></td>
                                <td>${status.active ? 'Ja' : 'Nein'}</td>
                                <td><c:out value="${status.sort_order}"/></td>
                                <td>
                                    <button class="button small" onclick="showStatusModal('edit', this)"
                                        data-id="${status.id}" data-name="${status.name}"
                                        data-active="${status.active}" data-sort-order="${status.sort_order}">
                                        Bearbeiten
                                    </button>
                                </td>
                            </tr>
                        </c:forEach>
                    </tbody>
                </table>
            </div>
        </div>
    </main>
</div>

<div id="statusModal" class="modal-overlay" style="display:none;">
    <div class="modal-content">
        <h3 id="statusModalTitle"></h3>
        <form id="statusForm" method="post" action="settings">
            <input type="hidden" name="action" id="statusAction"/>
            <input type="hidden" name="id" id="statusId"/>
            <div>
                <label>Name Status:</label>
                <input type="text" name="name" id="statusName" required/>
            </div>
            <div>
                <label>Reihenfolge:</label>
                <input type="number" name="sort_order" id="statusSortOrder" value="0" required/>
            </div>
            <div>
                <label><input type="checkbox" name="active" id="statusActive"> Aktiv</label>
            </div>
            <div class="modal-buttons">
                <button type="submit" class="button create">Speichern</button>
                <button type="button" class="button delete" onclick="hideStatusModal()">Abbrechen</button>
            </div>
        </form>
    </div>
</div>

<script>
    function showStatusModal(mode, btn) {
        const form = document.getElementById('statusForm');
        form.reset();
        if (mode === 'add') {
            document.getElementById('statusModalTitle').textContent = 'Neuen Status anlegen';
            document.getElementById('statusAction').value = 'add_status';
            document.getElementById('statusActive').checked = true;
        } else {
            document.getElementById('statusModalTitle').textContent = 'Status bearbeiten';
            document.getElementById('statusAction').value = 'edit_status';
            document.getElementById('statusId').value = btn.dataset.id;
            document.getElementById('statusName').value = btn.dataset.name;
            document.getElementById('statusSortOrder').value = btn.dataset.sortOrder;
            document.getElementById('statusActive').checked = (btn.dataset.active === 'true');
        }
        document.getElementById('statusModal').style.display = 'flex';
    }
    function hideStatusModal() {
        document.getElementById('statusModal').style.display = 'none';
    }
</script>
</body>
</html>