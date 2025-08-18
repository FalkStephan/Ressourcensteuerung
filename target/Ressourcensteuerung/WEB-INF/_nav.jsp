<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<nav>
    <h2>Menü</h2>
    <ul>
        <li><a href="${pageContext.request.contextPath}/index.jsp">Start</a></li>
        
        <!-- <li><a href="${pageContext.request.contextPath}/mitarbeiter">Mitarbeiter</a></li> -->

        <c:if test="${sessionScope.user.can_manage_users}">
            <li><a href="${pageContext.request.contextPath}/users/">Benutzer</a></li>
        </c:if>

        <c:if test="${sessionScope.user.can_manage_capacities}">
            <li><a href="${pageContext.request.contextPath}/capacities">Kapazitäten</a></li>
        </c:if>

        <c:if test="${sessionScope.user.can_manage_calendar}">
            <li><a href="${pageContext.request.contextPath}/calendar">Abwesenheiten</a></li>
        </c:if>

        <c:if test="${sessionScope.user.can_manage_calendar}">
            <li><a href="${pageContext.request.contextPath}/calendar_overview">Kalender</a></li>
        </c:if>

        <c:if test="${sessionScope.user.can_manage_tasks}">
            <li><a href="${pageContext.request.contextPath}/tasks">Aufgaben</a></li>
        </c:if>

        <c:if test="${sessionScope.user.can_manage_feiertage}">
            <li><a href="${pageContext.request.contextPath}/feiertage">Feiertage</a></li>
        </c:if>

        <c:if test="${sessionScope.user.can_view_logbook}">
            <li><a href="${pageContext.request.contextPath}/logbook">Logbuch</a></li>
        </c:if>

        <c:if test="${sessionScope.user.can_manage_settings}">
            <li><a href="${pageContext.request.contextPath}/settings">Einstellungen</a></li>
        </c:if>
    </ul>
    <div class="nav-footer">
        <ul>
            <li><a href="${pageContext.request.contextPath}/logout">Logout</a></li>
        </ul>
    </div>
</nav>