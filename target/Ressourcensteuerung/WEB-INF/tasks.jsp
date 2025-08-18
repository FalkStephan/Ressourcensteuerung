<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>
<!DOCTYPE html>
<html lang="de">
<head>
    <c:set var="title" value="Aufgaben" scope="request"/>
    <jsp:include page="/WEB-INF/_header.jsp"/>
</head>
<body>
<div class="layout-wrapper">
    <jsp:include page="/WEB-INF/_nav.jsp"/>
    <main>
        <div class="container">
            <h2>Aufgaben</h2>

            <button class="button create" onclick="showTaskModal('add')">Neue Aufgabe anlegen</button>

            <form id="filterForm" action="tasks" method="get" class="search-container">
                <input type="text" id="searchInput" name="search" value="<c:out value='${currentSearch}'/>" placeholder="Aufgabe suchen...">
                <select name="status_filter" onchange="this.form.submit()" style="margin-left: 1em;">
                    <option value="">-- Alle Status --</option>
                    <c:forEach var="status" items="${taskStatuses}">
                        <option value="${status.id}" ${currentStatusFilter == status.id ? 'selected' : ''}>
                            <c:out value="${status.name}"/>
                        </option>
                    </c:forEach>
                </select>
            </form>

            
            
            <table>
                <thead>
                    <tr>
                        <th>Aufgabe</th>
                        <th>Abteilung</th>
                        <th>Start</th>
                        <th>Ende</th>
                        <th>Aufwand (PT)</th>
                        <th>Status</th>
                        <th>Fortschritt (%)</th>
                        <th>Aktionen</th>
                    </tr>
                </thead>
                <tbody>
                    <c:forEach var="task" items="${tasks}">
                        <tr>
                            <td><c:out value="${task.name}"/></td>
                            <td><c:out value="${task.abteilung}"/></td>
                            <td><fmt:formatDate value="${task.start_date}" type="date" pattern="dd.MM.yyyy"/></td>
                            <td><fmt:formatDate value="${task.end_date}" type="date" pattern="dd.MM.yyyy"/></td>
                            <td><c:out value="${task.effort_days}"/></td>
                            <td>
                                <c:if test="${not empty task.status_name}">
                                    <span style="background-color: ${not empty task.status_color ? task.status_color : '#FFFFFF'}; padding: 3px 10px; border-radius: 999px; border: 1px solid #ccc; font-size: 0.9em;">
                                        <c:out value="${task.status_name}"/>
                                    </span>
                                </c:if>
                            </td>
                            <td>
                                <div style="display: flex; align-items: center; gap: 8px;">
                                    <div style="width: 100px; background-color: #e9ecef; border: 1px solid #ccc; border-radius: 5px; overflow: hidden;">
                                        <div style="width: ${task.progress_percent}%; background-color: #28a745; height: 18px;"></div>
                                    </div>
                                    <span><c:out value="${task.progress_percent}"/>%</span>
                                </div>
                            </td>
                            <td>
                                <button class="button small" onclick="showTaskModal('edit', this)"
                                    data-id="${task.id}" data-name="${task.name}"
                                    data-start-date="${task.start_date}" data-end-date="${task.end_date}"
                                    data-effort-days="${task.effort_days}" data-status-id="${task.status_id}"
                                    data-progress-percent="${task.progress_percent}"
                                    data-abteilung="${task.abteilung}">
                                    Bearbeiten
                                </button>
                            </td>
                        </tr>
                    </c:forEach>
                </tbody>
            </table>
        </div>
    </main>
</div>

<div id="taskModal" class="modal-overlay" style="display:none;">
    <div class="modal-content">
        <h3 id="taskModalTitle"></h3>
        <form id="taskForm" method="post" action="tasks">
            <input type="hidden" name="action" id="taskAction"/>
            <input type="hidden" name="id" id="taskId"/>
            <div><label>Name:</label><input type="text" name="name" id="taskName" required/></div>
            <div>
                <label>Abteilung:</label>
                <c:choose>
                    <c:when test="${sessionScope.user.see_all_users}">
                        <input type="text" name="abteilung" id="taskAbteilung" />
                    </c:when>
                    <c:otherwise>
                        <input type="text" name="abteilung" id="taskAbteilung" value="<c:out value='${sessionScope.user.abteilung}'/>" readonly />
                    </c:otherwise>
                </c:choose>
            </div>
            <div><label>Start-Datum:</label><input type="date" name="start_date" id="taskStartDate"/></div>
            <div><label>Ende-Datum:</label><input type="date" name="end_date" id="taskEndDate"/></div>
            <div><label>Aufwand (PT):</label><input type="number" step="0.1" name="effort_days" id="taskEffort" value="0" required/></div>
            <div><label>Fortschritt (%):</label><input type="number" name="progress_percent" id="taskProgress" value="0" min="0" max="100" required/></div>
            <div>
                <label>Status:</label>
                <select name="status_id" id="taskStatus" required>
                    <c:forEach var="status" items="${taskStatuses}">
                        <option value="${status.id}">${status.name}</option>
                    </c:forEach>
                </select>
            </div>
            <div class="modal-buttons">
                <button type="submit" class="button create">Speichern</button>
                <button type="button" class="button delete" onclick="hideTaskModal()">Abbrechen</button>
            </div>
        </form>
    </div>
</div>

<script>
    const searchInput = document.getElementById('searchInput');
    const filterForm = document.getElementById('filterForm');
    let debounceTimer;

    searchInput.addEventListener('keyup', () => {
        clearTimeout(debounceTimer);
        debounceTimer = setTimeout(() => {
            filterForm.submit();
        }, 500);
    });

    function showTaskModal(mode, btn) {
        const form = document.getElementById('taskForm');
        form.reset();
        
        const abteilungInput = document.getElementById('taskAbteilung');
        const userCanSeeAll = ${sessionScope.user.see_all_users};

        if (mode === 'add') {
            document.getElementById('taskModalTitle').textContent = 'Neue Aufgabe';
            document.getElementById('taskAction').value = 'add';
            if (!userCanSeeAll) {
                abteilungInput.value = "${sessionScope.user.abteilung}";
            }
        } else {
            document.getElementById('taskModalTitle').textContent = 'Aufgabe bearbeiten';
            document.getElementById('taskAction').value = 'edit';
            document.getElementById('taskId').value = btn.dataset.id;
            document.getElementById('taskName').value = btn.dataset.name;
            document.getElementById('taskStartDate').value = btn.dataset.startDate;
            document.getElementById('taskEndDate').value = btn.dataset.endDate;
            document.getElementById('taskEffort').value = btn.dataset.effortDays;
            document.getElementById('taskStatus').value = btn.dataset.statusId;
            document.getElementById('taskProgress').value = btn.dataset.progressPercent;
            // KORREKTUR: Fehlende Zeile zum Setzen der Abteilung
            abteilungInput.value = btn.dataset.abteilung;
        }
        document.getElementById('taskModal').style.display = 'flex';
    }
    
    function hideTaskModal() {
        document.getElementById('taskModal').style.display = 'none';
    }
</script>
</body>
</html>