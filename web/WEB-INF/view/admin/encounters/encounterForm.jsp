<%@ include file="/WEB-INF/template/include.jsp" %>

<openmrs:require privilege="View Encounters" otherwise="/login.htm" redirect="/admin/encounters/encounter.form" />

<%@ include file="/WEB-INF/template/header.jsp" %>
<%@ include file="localHeader.jsp" %>

<openmrs:htmlInclude file="/scripts/calendar/calendar.js" />
<openmrs:htmlInclude file="/scripts/dojo/dojo.js" />

<script type="text/javascript">
	dojo.require("dojo.widget.openmrs.ConceptSearch");
	dojo.require("dojo.widget.openmrs.PatientSearch");
	dojo.require("dojo.widget.openmrs.UserSearch");
	dojo.require("dojo.widget.openmrs.OpenmrsPopup");
	
	var uSearch;
	var userPopup;
	var pSearch;
	var patPopup;
	
	dojo.addOnLoad( function() {
		uSearch = dojo.widget.manager.getWidgetById("uSearch");
		userPopup = dojo.widget.manager.getWidgetById("uSelection");
		patPopup = dojo.widget.manager.getWidgetById("pSelection");
		pSearch = dojo.widget.manager.getWidgetById("pSearch");
		
		dojo.event.topic.subscribe("uSearch/select", 
			function(msg) {
				if (msg) {
					var user = msg.objs[0];
					userPopup.displayNode.innerHTML = '<a id="providerName" href="#View Provider" onclick="return gotoUser(null, ' + user.userId + ')">' + (user.firstName ? user.firstName : '') + ' ' + (user.middleName ? user.middleName : '') + ' ' + (user.lastName ? user.lastName : '') + '</a>';
					userPopup.hiddenInputNode.value = user.userId;
				}
			}
		);
		
		pSearch.getCellFunctions = function() {
			return [this.simpleClosure(pSearch, "getNumber"), 
					this.simpleClosure(pSearch, "getId"), 
					this.simpleClosure(pSearch, "getGiven"), 
					this.simpleClosure(pSearch, "getMiddle"), 
					this.simpleClosure(pSearch, "getFamily")
					];
		};
		
		dojo.event.topic.subscribe("pSearch/select", 
			function(msg) {
				if (msg) {
					var patient = msg.objs[0];
					patPopup.displayNode.innerHTML = '<a id="patientName" href="#View Patient" onclick="return gotoPatient(null, ' + patient.patientId + ')">' + patient.givenName + ' ' + patient.middleName + ' ' + patient.familyName + '</a>';
					patPopup.hiddenInputNode.value = patient.patientId;
				}
			}
		);
		
		toggle("div", "description");
		toggleVoided();
		voidedClicked(document.getElementById("voided"));
	})

</script>


<script type="text/javascript">

	var display = new Array();
	
	function mouseover(row, isDescription) {
		if (row.className.indexOf("searchHighlight") == -1) {
			row.className = "searchHighlight " + row.className;
			var other = getOtherRow(row, isDescription);
			other.className = "searchHighlight " + other.className;
		}
	}
	function mouseout(row, isDescription) {
		var c = row.className;
		row.className = c.substring(c.indexOf(" ") + 1, c.length);
		var other = getOtherRow(row, isDescription);
		c = other.className;
		other.className = c.substring(c.indexOf(" ") + 1, c.length);
	}
	function getOtherRow(row, isDescription) {
		if (isDescription == null) {
			var other = row.nextSibling;
			if (other.tagName == null)
				other = other.nextSibling;
		}
		else {
			var other = row.previousSibling;
			if (other.tagName == null)
				other = other.previousSibling;
		}
		return other;
	}
	function click(obsId) {
		document.location = "obs.form?obsId=" + obsId;
		return false;
	}
	
	function voidedClicked(input) {
		var reason = document.getElementById("voidReason");
		var voidedBy = document.getElementById("voidedBy");
		if (input.checked) {
			reason.style.display = "";
			if (voidedBy)
				voidedBy.style.display = "";
		}
		else {
			reason.style.display = "none";
			if (voidedBy)
				voidedBy.style.display = "none";
		}
	}
	
	function toggle(tagName, className) {
		if (display[tagName] == "none")
			display[tagName] = "";
		else
			display[tagName] = "none";
			
		var items = document.getElementsByTagName(tagName);
		for (var i=0; i < items.length; i++) {
			var classes = items[i].className.split(" ");
			for (x=0; x<classes.length; x++) {
				if (classes[x] == className)
					items[i].style.display = display[tagName];
			}
		}
		
		return false;
	}
	
	function toggleVoided() {
		toggle("tr", "voided");
		
		var table = document.getElementById("obs");
		
		if (table) {
			var rows = table.rows;
			var oddRow = true;
			
			for (var i=1; i<rows.length; i++) {
				if (rows[i].style.display == "") {
					var c = "";
					if (rows[i].className.substr(0, 6) == "voided")
						c = "voided ";
					if (oddRow)
						c = c + "oddRow";
					else
						c = c + "evenRow";
					oddRow = !oddRow;
					rows[i++].className = c;
					rows[i].className = c;
				}
			}
		}
		
		return false;
	}

	function gotoPatient(tagName, patId) {
		if (patId == null)
			patId = $(tagName).value;
		window.location = "${pageContext.request.contextPath}/admin/patients/patient.form?patientId=" + patId;
		return false;
	}
	
	function gotoUser(tagName, userId) {
		if (userId == null)
			userId = $(tagName).value;
		window.location = "${pageContext.request.contextPath}/admin/users/user.form?userId=" + userId;
		return false;
	}

</script>

<style>
	#table th { text-align: left; }
</style>

<h2><spring:message code="Encounter.manage.title"/></h2>

<spring:hasBindErrors name="encounter">
	<spring:message code="fix.error"/>
	<br />
</spring:hasBindErrors>

<b class="boxHeader"><spring:message code="Encounter.summary"/></b>
<div class="box">
	<form method="post">
	<table cellpadding="3" cellspacing="0">
		<tr>
			<th><spring:message code="Encounter.patient"/></th>
			<td>
				<spring:bind path="encounter.patient">
					<div dojoType="PatientSearch" widgetId="pSearch" patientId="${status.value.patientId}"></div>
					<div dojoType="OpenmrsPopup" widgetId="pSelection" hiddenInputName="patientId" searchWidget="pSearch" searchTitle='<spring:message code="Patient.find"/>' <c:if test="${encounter.encounterId != null}">allowSearch="false"</c:if> ></div>
					
					<c:if test="${status.errorMessage != ''}"><span class="error">${status.errorMessage}</span></c:if>
				</spring:bind>
			</td>
		</tr>
		<tr>
			<th><spring:message code="Encounter.provider"/></th>
			<td>
				<spring:bind path="encounter.provider">
					<div dojoType="UserSearch" widgetId="uSearch" userId="${status.value.userId}" roles="Provider;"></div>
					<div dojoType="OpenmrsPopup" widgetId="uSelection" hiddenInputName="providerId" searchWidget="uSearch" searchTitle='<spring:message code="Encounter.provider.find"/>'></div>
					<c:if test="${status.errorMessage != ''}"><span class="error">${status.errorMessage}</span></c:if>
				</spring:bind>
			</td>
		</tr>
		<tr>
			<th><spring:message code="Encounter.location"/></th>
			<td>
				<spring:bind path="encounter.location">
					<select name="location">
						<openmrs:forEachRecord name="location">
							<option value="${record.locationId}" <c:if test="${status.value == record.locationId}">selected</c:if>>${record.name}</option>
						</openmrs:forEachRecord>
					</select>
					<c:if test="${status.errorMessage != ''}"><span class="error">${status.errorMessage}</span></c:if>
				</spring:bind>
			</td>
		</tr>
		<tr>
			<th><spring:message code="Encounter.datetime"/></th>
			<td>
				<spring:bind path="encounter.encounterDatetime">			
					<input type="text" name="${status.expression}" size="10" 
						   value="${status.value}" onClick="showCalendar(this)" />
				   (<spring:message code="general.format"/>: ${datePattern})
					<c:if test="${status.errorMessage != ''}"><span class="error">${status.errorMessage}</span></c:if> 
				</spring:bind>
			</td>
		</tr>
		<tr>
			<th><spring:message code="Encounter.type"/></th>
			<td>
				<spring:bind path="encounter.encounterType">
					<c:choose>
						<c:when test="${encounter.encounterId == null}">
							<select name="encounterType">
								<c:forEach items="${encounterTypes}" var="type">
									<option value="${type.encounterTypeId}" <c:if test="${type.encounterTypeId == status.value}">selected</c:if>>${type.name}</option>
								</c:forEach>
							</select>
						</c:when>
						<c:otherwise>
							${encounter.encounterType.name}
						</c:otherwise>
					</c:choose>
					<c:if test="${status.errorMessage != ''}"><span class="error">${status.errorMessage}</span></c:if>
				</spring:bind>
			</td>
		</tr>
		<tr>
			<th><spring:message code="Encounter.form"/></th>
			<td>
				<spring:bind path="encounter.form">
					<c:choose>
						<c:when test="${encounter.encounterId == null}">
							<select name="form">
								<option value=""></option>
								<c:forEach items="${forms}" var="form">
									<option value="${form.formId}" <c:if test="${form.formId == status.value}">selected</c:if>>${form.name}</option>
								</c:forEach>
							</select>
						</c:when>
						<c:otherwise>
							${encounter.form.name}
						</c:otherwise>
					</c:choose>
					<c:if test="${status.errorMessage != ''}"><span class="error">${status.errorMessage}</span></c:if>
				</spring:bind>
			</td>
		</tr>
		<c:if test="${!(encounter.creator == null)}">
			<tr>
				<th><spring:message code="general.createdBy" /></th>
				<td>
					<a href="#View User" onclick="return gotoUser(null, '${encounter.creator.userId}')">${encounter.creator.firstName} ${encounter.creator.lastName}</a> -
					<openmrs:formatDate date="${encounter.dateCreated}" type="medium" />
				</td>
			</tr>
		</c:if>
		<tr>
			<th><spring:message code="general.voided" /></th>
			<td>
				<spring:bind path="encounter.voided">
					<input type="hidden" name="_${status.expression}" />
					<input type="checkbox" name="${status.expression}" id="voided" onClick="voidedClicked(this)" <c:if test="${encounter.voided}">checked</c:if> />					
					<c:if test="${status.errorMessage != ''}"><span class="error">${status.errorMessage}</span></c:if>
				</spring:bind>
			</td>
		</tr>
		<tr id="voidReason">
			<th><spring:message code="general.voidReason" /></th>
			<td>
				<spring:bind path="encounter.voidReason">
					<input type="text" value="${status.value}" name="${status.expression}" size="40" />
					<c:if test="${status.errorMessage != ''}"><span class="error">${status.errorMessage}</span></c:if>
				</spring:bind>
			</td>
		</tr>
		<c:if test="${!(encounter.voidedBy == null)}">
			<tr id="voidedBy">
				<th><spring:message code="general.voidedBy" /></th>
				<td>
					<a href="#View User" onclick="return gotoUser(null, '${encounter.voidedBy.userId}')">${encounter.voidedBy.firstName} ${encounter.voidedBy.lastName}</a> -
					<openmrs:formatDate date="${encounter.dateVoided}" type="medium" />
				</td>
			</tr>
		</c:if>
	</table>
	
	<input type="hidden" name="phrase" value='<request:parameter name="phrase" />'/>
	<input type="submit" value='<spring:message code="Encounter.save"/>'>
	&nbsp;
	<input type="button" value='<spring:message code="general.cancel"/>' onclick="history.go(-1); return; document.location='index.htm?autoJump=false&phrase=<request:parameter name="phrase"/>'">
	</form>
</div>

<c:if test="${encounter.encounterId != null}">
	<br/>
	<div class="boxHeader">
		<span style="float: right">
			<a href="#" id="showDescription" onClick="return toggle('div', 'description')"><spring:message code="general.toggle.description"/></a> |
			<a href="#" id="showVoided" onClick="return toggleVoided()"><spring:message code="general.toggle.voided"/></a>
		</span>
		<b><spring:message code="Encounter.observations"/></b>
	</div>
	<div class="box">
	<table cellspacing="0" cellpadding="2" width="98%" id="obs">
				<tr>
			<th></th>
			<th><spring:message code="Obs.concept"/></th>
			<th><spring:message code="Obs.value"/></th>
			<th></th>
			<th><spring:message code="Obs.creator.or.changedBy"/></th>
		</tr>
		<c:forEach items="${observations}" var="obs" varStatus="status">
			<% pageContext.setAttribute("field", ((java.util.Map)request.getAttribute("obsMap")).get(pageContext.getAttribute("obs"))); %>
			<tr class="<c:if test="${obs.voided}">voided </c:if><c:choose><c:when test="${count % 2 == 0}">evenRow</c:when><c:otherwise>oddRow</c:otherwise></c:choose>" onmouseover="mouseover(this)" onmouseout="mouseout(this)" onclick="click('${obs.obsId}')">
				<td>${field.fieldNumber}<c:if test="${field.fieldPart != null && field.fieldPart != ''}">.${field.fieldPart}</c:if></td>
				<td><a href="obs.form?obsId=${obs.obsId}" onclick="return click('${obs.obsId}')"><%= ((org.openmrs.Obs)pageContext.getAttribute("obs")).getConcept().getName((java.util.Locale)request.getAttribute("locale")) %></a></td>
				<td><%= ((org.openmrs.Obs)pageContext.getAttribute("obs")).getValueAsString((java.util.Locale)request.getAttribute("locale")) %></td>
				<td valign="middle" valign="right">
					<c:if test="${fn:contains(editedObs, obs.obsId)}"><img src="${pageContext.request.contextPath}/images/alert.gif" title='<spring:message code="Obs.edited"/>' /></c:if>
					<c:if test="${obs.comment != null && obs.comment != ''}"><img src="${pageContext.request.contextPath}/images/note.gif" title="${obs.comment}" /></c:if>
				</td>
				<td style="white-space: nowrap;">
					${obs.creator.firstName} ${obs.creator.lastName} -
					<openmrs:formatDate date="${obs.dateCreated}" type="medium" />
				</td>
			</tr>
			<tr class="<c:if test="${obs.voided}">voided </c:if><c:choose><c:when test="${status.index % 2 == 0}">evenRow</c:when><c:otherwise>oddRow</c:otherwise></c:choose>" onmouseover="mouseover(this, true)" onmouseout="mouseout(this, true)" onclick="click('${obs.obsId}')">
				<td colspan="5"><div class="description"><%= ((org.openmrs.Obs)pageContext.getAttribute("obs")).getConcept().getName((java.util.Locale)request.getAttribute("locale")).getDescription() %></div></td>
			</tr>
		</c:forEach>
	</table>
	</div>
</c:if>

<br />
<a href="obs.form?encounterId=${encounter.encounterId}"><spring:message code="Obs.add"/></a>
<br />

<%@ include file="/WEB-INF/template/footer.jsp" %>