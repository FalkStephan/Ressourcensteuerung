<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<nav>
    <h2>Menü</h2>
    <ul>
        <li><a href="${pageContext.request.contextPath}/index.jsp">Start</a></li>
        
        <li><a href="${pageContext.request.contextPath}/mitarbeiter">Mitarbeiter</a></li>

        <c:if test="${sessionScope.user.can_manage_users}">
            <li><a href="${pageContext.request.contextPath}/users">Benutzer</a></li>
        </c:if>

        <c:if test="${sessionScope.user.can_view_logbook}">
            <li><a href="${pageContext.request.contextPath}/logbook">Logbuch</a></li>
        </c:if>
    </ul>
    <div class="nav-footer">
        <ul>
            <li><a href="${pageContext.request.contextPath}/logout">Logout</a></li>
        </ul>
    </div>
</nav>