<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<!DOCTYPE html>
<html lang="de">
<head>
    <c:set var="title" value="Einstellungen" scope="request"/>
    <jsp:include page="/WEB-INF/_header.jsp"/>
    <style>
        .settings-section {
            margin-bottom: 2em;
            background: #fff;
            padding: 1em;
            border-radius: 4px;
            box-shadow: 0 1px 3px rgba(0,0,0,0.1);
        }
        .settings-section h3 {
            margin-top: 0;
            padding-bottom: 0.5em;
            border-bottom: 1px solid #eee;
        }
        .settings-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 1em;
            margin-top: 1em;
        }
        .setting-item {
            display: flex;
            align-items: center;
            gap: 1em;
            padding: 0.5em;
        }
        .setting-item label {
            flex: 1;
        }
        .color-preview {
            width: 30px;
            height: 30px;
            border: 1px solid #ccc;
            display: inline-block;
            vertical-align: middle;
            margin-left: 0.5em;
            border-radius: 4px;
        }
        .color-input-group {
            display: flex;
            align-items: center;
            gap: 0.5em;
        }
        input[type="color"] {
            padding: 0;
            width: 50px;
            height: 30px;
        }
    </style>
</head>
<body>
<div class="layout-wrapper">
    <jsp:include page="/WEB-INF/_nav.jsp"/>
    <main>
        <div class="container">
            <h2>Einstellungen</h2>
            <!-- Kalenderfarben -->
            <div class="settings-section">
                <h3>Kalenderfarben</h3>
                <form id="colorSettingsForm" method="post" action="${pageContext.request.contextPath}/settings">
                    <input type="hidden" name="action" value="update_settings">
                    <div class="settings-grid">
                        <c:forEach var="setting" items="${settings}">
                            <c:if test="${setting.key.startsWith('calendar_color_')}">
                                <div class="setting-item">
                                    <label for="${setting.key}">${setting.description}:</label>
                                    <div class="color-input-group">
                                        <input type="color" 
                                               id="${setting.key}" 
                                               name="${setting.key}" 
                                               value="${setting.value}"
                                               onchange="updatePreview(this)">
                                        <span class="color-preview" 
                                              id="preview_${setting.key}" 
                                              style="background-color: ${setting.value}">
                                        </span>
                                    </div>
                                </div>
                            </c:if>
                        </c:forEach>
                    </div>
                    <div style="margin-top: 1em;">
                        <button type="submit" class="button create">Farben speichern</button>
                    </div>
                </form>
            </div>

            <!-- Task-Status -->
            <div class="settings-section">
                <h3>Status "Aufgaben"</h3>
                <button class="button create small" onclick="showStatusModal('add')">Neuen Status anlegen</button>
                <table>
                    <thead><tr><th>Name</th><th>Aktiv</th><th>Reihenfolge</th><th>Farbe</th><th>Aktionen</th></tr></thead>
                    <tbody>
                        <c:forEach var="status" items="${taskStatuses}">
                            <tr>
                                <td><c:out value="${status.name}"/></td>
                                <td>${status.active ? 'Ja' : 'Nein'}</td>
                                <td><c:out value="${status.sort_order}"/></td>
                                <td>
                                   <div style="display: flex; align-items: center; gap: 8px;">
                                        <div style="width: 20px; height: 20px; background-color: ${status.color_code}; border: 1px solid #777; border-radius: 4px;"></div>
                                        <span><c:out value="${status.color_code}"/></span>
                                    </div>
                                </td>
                                <td>
                                    <button class="button small" onclick="showStatusModal('edit', this)"
                                        data-id="${status.id}" data-name="${status.name}"
                                        data-active="${status.active}" 
                                        data-sort-order="${status.sort_order}"
                                        data-color-code="${status.color_code}">
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
                <label>Farbcode:</label>
                <input type="color" name="color_code" id="statusColorCode" value="#FFFFFF"/>
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
    // Farb-Preview aktualisieren
    function updatePreview(input) {
        document.getElementById('preview_' + input.id).style.backgroundColor = input.value;
    }

    function showStatusModal(mode, btn) {
        const form = document.getElementById('statusForm');
        form.reset();
        if (mode === 'add') {
            document.getElementById('statusModalTitle').textContent = 'Neuen Status anlegen';
            document.getElementById('statusAction').value = 'add_status';
            document.getElementById('statusActive').checked = true;
            document.getElementById('statusColorCode').value = '#FFFFFF';
        } else {
            document.getElementById('statusModalTitle').textContent = 'Status bearbeiten';
            document.getElementById('statusAction').value = 'edit_status';
            document.getElementById('statusId').value = btn.dataset.id;
            document.getElementById('statusName').value = btn.dataset.name;
            document.getElementById('statusSortOrder').value = btn.dataset.sortOrder;
            document.getElementById('statusActive').checked = (btn.dataset.active === 'true');
            document.getElementById('statusColorCode').value = btn.dataset.colorCode;
        }
        document.getElementById('statusModal').style.display = 'flex';
    }
    function hideStatusModal() {
        document.getElementById('statusModal').style.display = 'none';
    }
</script>
</body>
</html>